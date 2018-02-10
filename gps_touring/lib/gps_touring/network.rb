require 'nokogiri'
require_relative 'logical_graph'
require_relative 'logical_edge'
require_relative 'original_edge'
require_relative 'elevation_edge'
require_relative 'network_point'
require_relative 'gpx/builder'

module GpsTouring
  class Network
    # A Network is the container for all of the waypionts read in from GPX files.
    # It has a Hash indexed by the lat/long of the waypoint so that points with identical lat/long
    # are regarded as being co-located, and can have links to 1, 2, 3,... more points 
    attr_reader :points, :logical_edges, :logical_graphs
    def initialize(gpx_files)
      @points = Hash.new {|h, k| h[k] = NetworkPoint.new}
      gpx_files.each {|f|
	doc = Nokogiri::XML(File.open(f), &:noblanks)
	trks = doc.css('trk')
	trks.each {|trk|
	  trksegs = trk.css('trkseg')
	  trksegs.each {|trkseg|
	    process_wpts(trkseg.css('trkpt'))
	  }
	}
	rtes = doc.css('rte')
	rtes.each {|rte|
	  process_wpts(rte.css('rtept'))
	}
      }
      @logical_edges = make_logical_edges
      @logical_graphs = make_logical_graphs

      sanity_check
    end
    def sanity_check
      points.values.each {|p| p.sanity_check}
    end
    def set_calling_points(gpx_file)
      doc = Nokogiri::XML(File.open(gpx_file), &:noblanks)
      wpts = doc.css('wpt')
      wpts.each {|wpt|
	key = wpt2key(wpt)
	pre_existing_points = nil
	unless @points.has_key? key
	  # There's no NetworkPoint with the same lat/lon as this wpt.
	  # So we need to find the nearest one, and link to that.
	  # So we remember the points we have before adding this wpt:
	  pre_existing_points = @points.values.dup
	end
	calling_point = @points[key].add_calling_point(wpt)
	if pre_existing_points
	  nearest_point = find_nearest_point(calling_point, pre_existing_points)
	  calling_point.add_link_to(nearest_point)
	end
      }
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
    def logical_nodes
      # If a NetworkPoint has exactly two links, then it is interior to a simple sequence of points:
      # One line is to bo to the previous point, one to go to the next. That's all.
      #
      # A NetworkPoint with one link is an end point.
      # A NetworkPoint with more than two links is a 'junction'.
      # logical_nodes are these end points and junctions.
      @points.values.find_all {|point| point.link_count != 2}
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
    def wpt2key(wpt)
      # key for the @points hash:
      [wpt['lat'], wpt['lon']]
    end
    def process_wpts(wpts)
      # add a saquence of waypoints that are part of a sequence 
      # (from a <trkseg>,or <rte>)
      curr_wpt = nil
      wpts.each {|wpt|
	add_point(wpt)
	add_link(curr_wpt, wpt)
	curr_wpt = wpt
      }
    end
    def add_point(wpt)
      @points[wpt2key(wpt)].add_wpt(wpt)
    end
    def add_link(wpt1, wpt2)
      # May be called with one waypoint nil - if so, no link to add
      if wpt1 && wpt2
	@points.has_key?(wpt2key(wpt1)) || raise("@points has no key for wpt1")
	@points.has_key?(wpt2key(wpt2)) || raise("@points has no key for wpt2")
	@points[wpt2key(wpt1)].add_link_to(@points[wpt2key(wpt2)])
	@points[wpt2key(wpt2)].add_link_to(@points[wpt2key(wpt1)])
      end
    end
    def make_logical_edges
      # NetworkPoints that have exactly 2 links are in the middle of a 'chain' of points, 
      # so they are not the start of a LogicalEdge.
      # All other points are the start of a LogicalEdge:
      logical_nodes.map {|point|
	# Create new LogicalEdge from p in the direction of link
	point.links.map{|link| LogicalEdge.new(point, link, logical_nodes)}
      }.flatten
    end
    def make_logical_graphs
      # returns an array of LogicalGraphs
      # Each member of the array is a complete list of connected logical_edges
      logical_graphs = []
      remaining_edges = logical_edges
      # while there are still logical_edges that have not been included in a LogicalGraph:
      while e = remaining_edges.first
	# Grow the graph to included all (transitively) connected logical_edges
	logical_graphs << LogicalGraph.new(e.from)
	remaining_edges = remaining_edges - logical_graphs.last.logical_edges
      end
      logical_graphs
    end
  end
end