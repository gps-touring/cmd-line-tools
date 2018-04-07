require 'nokogiri'
require_relative 'logical_graph'
require_relative 'original_edge'
require_relative 'elevation_edge'
require_relative 'network_point'
require_relative 'gpx/builder'

module GpsTouring
  class Network
    # A Network is the container for all of the waypionts read in from GPX files.
    # It has a Hash indexed by the lat/long of the waypoint so that points with identical lat/long
    # are regarded as being co-located, and can have links to 1, 2, 3,... more points 
    attr_reader :points
    def initialize(gpx_files)
      @points = Hash.new {|h, k| h[k] = NetworkPoint.new(k)}

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

      sanity_check
    end
    def logical_edges
      logical_graphs.map {|g|g.edges }.flatten
    end
    def logical_graphs
      make_logical_graphs
    end
    def sanity_check
      points.values.each {|p| p.sanity_check}
    end
    def sequence_points
      @points.values.find_all {|p| p.sequence_point? }
    end
    def set_calling_points(gpx_file)
      # Returns sequence of NetworkPoints corresponding to these
      # calling points:
      network_points = []
      seq_pts = sequence_points
      doc = Nokogiri::XML(File.open(gpx_file), &:noblanks)
      wpts = doc.css('wpt')
      wpts.each {|wpt|
	point_def = PointDefinition::from_gpx_waypoint(wpt)
	point_def.type = PointDefinition::Type::CALLING_POINT
	calling_point = @points[point_def.geoloc].add_definition(point_def)
	network_points << calling_point
	if calling_point.links.size == 0
	  # If calling point is detatched, link it into a SEQUENCE point
	  # (i.e. one that's joined to others in the network)
	  nearest_point = find_nearest_point(calling_point, seq_pts)
	  calling_point.add_bidirectional_link(nearest_point)
	end
      }
      network_points
    end
    def find_nearest_point(to_p, from_points)
      min_dist = Float::INFINITY
      nearest_point = nil
      from_points.each {|p|
	dist = p.distance_m(to_p)
	if dist < min_dist
	  nearest_point = p
	  min_dist = dist
	end
      }
      nearest_point
    end
    def find_route(calling_points, edge_cost_method)
      # calling_points are NetworkPoints
      errors = 0
      calling_points.each {|cp|
	unless logical_nodes.include? cp
	  $stderr.puts "Software error: Calling point #{cp.to_s} is not one of the Network's logicalnodes"
	  errors += 1
	end
      }
      raise "Abandon due to error" if errors > 0
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
      # If a NetworkPoint has exactly two links, then it is interior to a simple sequence of points:
      # One link goes to the previous point, the other link to the next. That's all.
      #
      # A NetworkPoint with one link is an end point.
      # A NetworkPoint with more than two links is a 'junction'.
      # logical_nodes are these end points and junctions.
      # Calling Points are also logical nodes.
      @points.values.find_all {|point| point.link_count != 2 || point.calling_point?}
    end
    def logical_graphs_gpx
      GPX::Builder.new {|xml|
	logical_graphs.each {|graph|
	  graph.to_gpx_trk(xml)
	}
      }.to_xml
    end
    def dump
      @points.keys.each {|k|
	puts "#{k} #{@points[k].link_count}"
      }
      puts logical_graphs
    end
    private
    def add_waypoint_sequence(wpts)
      # add a saquence of waypoints that are part of a sequence 
      # (from a <trkseg>,or <rte>)
      curr_nwk_point = nil
      wpts.each {|wpt|
	nwk_point = add_waypoint(wpt)
	add_link(curr_nwk_point, nwk_point)
	curr_nwk_point = nwk_point
      }
    end
    def add_waypoint(wpt)
      point_def = PointDefinition::from_gpx_waypoint(wpt)
      point_def.type = PointDefinition::Type::SEQUENCE_POINT
      @points[point_def.geoloc].add_definition(point_def)
    end
    def add_link(pt1, pt2)
      # May be called with one waypoint nil - if so, no link to add
      if pt1 && pt2
	pt1.add_bidirectional_link(pt2)
      end
    end
    def make_logical_graphs
      # returns an array of LogicalGraphs
      logical_graphs = []
      remaining_nodes = logical_nodes

      while n = remaining_nodes.first
	g = logical_graph(n, remaining_nodes)
	logical_graphs << g
	remaining_nodes = remaining_nodes - g.nodes
      end
      logical_graphs
    end
    def logical_graph(node, nodes)
      # Return the LogicalGraph containing node where other
      # nodes in the graph are in the array nodes
      nodes_hash = Hash[nodes.map{|n| [n, true]}]
      node_test = lambda{|n| nodes_hash[n]}
      LogicalGraph.new(node, node_test)
    end
  end
end
