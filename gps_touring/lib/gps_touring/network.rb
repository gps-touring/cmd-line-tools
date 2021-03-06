require 'nokogiri'
require_relative 'logical_graph'
require_relative 'original_edge'
require_relative 'elevation_edge'
require_relative 'network_point'
require_relative 'gpx/builder'

module GpsTouring
  class Points
    def initialize
      # Hash of points, indexed by [lat,long], aka geoloc.
      @pHash = Hash.new {|h, k| h[k] = NetworkPoint.new(k)}
    end
    def add_definition(point_def)
      @pHash[point_def.geoloc].add_definition(point_def)
    end
    def all
      @pHash.values
    end
    def sequence_points
      @pHash.values.find_all {|p| p.sequence_point? }
    end
    def calling_points
      @pHash.values.find_all {|p| p.calling_point? }
    end
    def intersection_points
      @pHash.values.find_all {|p| p.intersection_point?}
    end
    def logical_nodes
      # If a NetworkPoint has exactly two links, then it is interior to a simple sequence of points:
      # One link goes to the previous point, the other link to the next. That's all.
      #
      # A NetworkPoint with one link is an end point.
      # A NetworkPoint with more than two links is a 'junction'.
      # logical_nodes are these end points and junctions.
      # Calling Points are also logical nodes.
      @pHash.values.find_all {|point|
	point.link_count != 2 || point.calling_point?
	# Should already be including intersection_points because all should 
	# have more than 2 links. So don't need:
	#point.link_count != 2 || point.calling_point? || point.intersection_point?
      }
    end
    def find(geoloc)
      @pHash.has_key?(geoloc) ? @pHash[geoloc] : nil
    end
    def self.to_wpt_gpx(points)
      GPX::Builder.new {|xml|
	points.each {|p|
	  p.to_gpx_wpt(xml)
	}
      }.to_xml
    end
  end
  class Network
    attr_reader :points
    def initialize(gpx_files)
      @points = Points.new
      @line_segments = LineSegments.new

      gpx_files.each {|f|
	doc = Nokogiri::XML(File.open(f), &:noblanks)
	trks = doc.css('trk')
	trks.each {|trk|
	  trksegs = trk.css('trkseg')
	  trksegs.each {|trkseg|
	    add_waypoint_sequence(trkseg.css('trkpt'))
	  }
	}
	rtes = doc.css('rte')
	rtes.each {|rte|
	  add_waypoint_sequence(rte.css('rtept'))
	}
      }
      #puts "Line segments: #{@line_segments.all.size}"
      puts "logical nodes before add_intersection_points: #{logical_nodes.size}"
      add_intersection_points
      puts "logical nodes after add_intersection_points: #{logical_nodes.size}"

      sanity_check
    end
    def logical_edges
      logical_graphs.map {|g|g.edges }.flatten
    end
    def logical_graphs
      make_logical_graphs
    end
    def sanity_check
      @points.all.each {|p| p.sanity_check}
    end
    def add_intersection_points
      # If there are line segments in the network that cross, 
      # and where there is no existing NetworkPoint at the point of intersection,
      # we want to define new NetworkPoints at these intersection points.
      #
      # We obtain a list of intersecting line segments:
      @line_segments.all.each {|ls|
	raise "Huh? no LineSegments key for #{ls.to_s}" unless @line_segments.include?(ls)
      }
      intersections = Geo::intersecting_line_segments(@line_segments.all)
      intersections.each {|i|
	ls1, ls2 = i.line_segments
	puts "Intersection at #{i.point.as_s}, ele: #{Geo::intersection_ele(i)}"
	intersection_point = @points.add_definition(IntersectionPoint::new(
	  lat: i.point.y,
	  lon: i.point.x,
	  ele: Geo::intersection_ele(i),
	  name: "Intersection of #{ls1.name} and #{ls2.name}"
	))
	i.line_segments.each {|ls|
	  #raise "Huh? no LineSegments key for #{ls.to_s}" unless @line_segments.include?(ls)
	  ls.each {|p|
	    q = @points.find(p.geoloc) 
	    unless q && p.object_id == q.object_id
	      $stderr.puts "Point at an end of a line segment does not exist in netowrk points"
	    end
	  }
	}
	@line_segments.remove(ls1)
	@line_segments.remove(ls2)
	@line_segments.add(intersection_point, ls1[0])
	@line_segments.add(intersection_point, ls1[1])
	@line_segments.add(intersection_point, ls2[0])
	@line_segments.add(intersection_point, ls2[1])
	if (intersection_point.links.size < 4)
	  $stderr.puts "IntersectionPoint #{intersection_point.name} has too few links."
	  $stderr.puts "Found links:"
	  $stderr.puts intersection_point.links.map {|p|
	    p.to_s
	  }.join("\n")
	  abort
	end
	#puts "Links to intersection: #{intersection_point.links.size}"
      }
    end
    def set_calling_points(gpx_file)
      # Returns sequence of NetworkPoints corresponding to these
      # calling points:
      network_points = []
      seq_pts = @points.sequence_points
      doc = Nokogiri::XML(File.open(gpx_file), &:noblanks)
      wpts = doc.css('wpt')
      wpts.each {|wpt|
	calling_point = @points.add_definition(CallingPoint::from_gpx_waypoint(wpt))
	network_points << calling_point
	if calling_point.links.size == 0
	  # If calling point is detatched, link it into a SEQUENCE point
	  # (i.e. one that's joined to others in the network)
	  nearest_point = Geo::find_nearest_point(calling_point, seq_pts)
	  #calling_point.add_bidirectional_link(nearest_point)
	  @line_segments.add(calling_point, nearest_point)
	end
      }
      network_points
    end
    def find_route(calling_points, edge_cost_method)
      # calling_points are NetworkPoints
      errors = 0
      graph = logical_graph(calling_points.first, logical_nodes)
      calling_points.each {|cp|
	unless graph.nodes.include? cp
	  $stderr.puts "Calling point #{cp.to_s} is not in the same LogicalGraph as the starting point #{calling_points.first}"
	  errors += 1
	end
      }
      raise "Abandon due to error" if errors > 0

      Route.new(graph, calling_points, edge_cost_method)

    end
    def logical_nodes
      @points.logical_nodes
    end
    def logical_graphs_gpx
      GPX::Builder.new {|xml|
	logical_graphs.each {|graph|
	  graph.to_gpx_trk(xml)
	}
      }.to_xml
    end
    def intersection_points_gpx
      Points::to_wpt_gpx(@points.intersection_points)
    end
    private
    def add_waypoint_sequence(wpts)
      # add a saquence of waypoints that are part of a sequence 
      # (from a <trkseg>,or <rte>)
      curr_nwk_point = nil
      wpts.each {|wpt|
	nwk_point = @points.add_definition(SequencePoint::from_gpx_waypoint(wpt))
	#add_link(curr_nwk_point, nwk_point)
	@line_segments.add(curr_nwk_point, nwk_point) if curr_nwk_point
	curr_nwk_point = nwk_point
      }
    end
    #def add_link(pt1, pt2)
      ## May be called with one waypoint nil - if so, no link to add
      #if pt1 && pt2
	#pt1.add_bidirectional_link(pt2)
      #end
    #end
    private def make_logical_graphs
      # returns an array of LogicalGraphs
      logical_graphs = []
      remaining_nodes = logical_nodes

      while n = remaining_nodes.first
	puts "Creating logical_graph from #{n.to_s}, remaining_nodes: #{remaining_nodes.size}"
	g = logical_graph(n, remaining_nodes)
	logical_graphs << g
	remaining_nodes = remaining_nodes - g.nodes
      end
      logical_graphs
    end
    private def logical_graph(node, nodes)
      # Return the LogicalGraph containing node where other
      # nodes in the graph are in the array nodes
      nodes_hash = Hash[nodes.map{|n| [n, true]}]
      node_test = lambda{|n| nodes_hash[n]}
      LogicalGraph.new(node, node_test)
    end
  end
end
