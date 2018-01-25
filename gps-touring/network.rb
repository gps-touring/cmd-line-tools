require 'nokogiri'
require_relative 'logical-graph'
require_relative 'logical-edge'
require_relative 'network-point'

module GpsTouring
  class Network
    # A Network is the container for all of the waypionts read in from GPX files.
    # It has a Hash indexed by the lat/long of the waypoint so that points with identical lat/long
    # are regarded as being co-located, and can have links to 1, 2, 3,... more points 
    attr_reader :points, :edges, :logical_graphs
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
      @edges = make_edges
      @logical_graphs = make_graphs
    end
    def logical_graphs_gpx
      Nokogiri::XML::Builder.new {|xml|
	xml.gpx(xmlns: "http://www.topografix.com/GPX/1/1", version: "1.1") {
	  logical_graphs.each {|graph|
	    graph.to_gpx(xml)
	  }
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
    def make_edges
      # NetworkPoints that have exactly 2 links are in the middle of a 'chain' of points, 
      # so they are not the start of a LogicalEdge.
      # All other points are the start of a LogicalEdge:
      @points.values.find_all {|point| point.link_count != 2}.map {|point|
	# Create new LogicalEdge from p in the direction of link
	point.links.map{|link| LogicalEdge.new(point, link)}
      }.flatten
    end
    def make_graphs
      # returns an array of LogicalGraphs
      # Each member of the array is a complete list of connected edges
      logical_graphs = []
      remaining_edges = edges
      # while there are still edges that have not been included in a LogicalGraph:
      while e = remaining_edges.first
	# Grow the graph to included all (transitively) connected edges
	logical_graphs << LogicalGraph.new(e.from)
	remaining_edges = remaining_edges - logical_graphs.last.edges
      end
      logical_graphs
    end
  end
end
