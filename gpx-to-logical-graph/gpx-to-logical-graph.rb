require 'nokogiri'
require 'pp'

# Takes a set of GPS tracks/routes and produces a logical graph.
# The logical graph is a GPX file with all points missed out unless they are end points or junctions.
# In other words, each point in the output has1, 3 or more than three points to which it is connected,
# but never 2.
#
# In this version, lat/long must be identical for two wayppoints to be recognized as the same.
#  - a future vesrion may allow them to be 'close'

class Point
  attr_reader :links, :edges
  def initialize
    @wpts = []
    @links = []
    @edges = []
  end
  def add_wpt(wpt)
    @wpts << wpt
  end
  def add_link_to(p)
    return if p === self
    # p will already be in @links if there is a sequence of waypoints like this:
    # p, q, p
    # and here we would have self == q
    # In this case q must be treated as the end of an edge - i.e. it will have just one link.
    @links << p unless @links.include?(p)
  end
  def add_edge(e)
    e.from === self || raise("Bug - expected all edges are from this point")
    @edges << e
  end
  def link_count
    @links.size
  end
  def to_s
    @wpts.first.to_s
  end
  def lat
    @wpts.first['lat']
  end
  def lon
    @wpts.first['lon']
  end
  def to_gpx(xml)
    xml.trkpt(lat: lat, lon: lon) {
      name = @wpts.map {|w| n = w.at_css('name'); n || nil}.compact
      unless name.empty?
	xml.name(name.join('|'))
      end
    }
  end
end
class DirectedEdge
  attr_reader :from, :to, :hops
  def initialize(point, link)
    @hops = 1
    @from = point
    while link.link_count == 2
      next_links = link.links - [point]
      unless next_links.size == 1
	$stderr.puts "point:"
	$stderr.puts point
	$stderr.puts "link:"
	$stderr.puts link
	$stderr.puts "link.links:"
	$stderr.puts link.links.map{|x| x.object_id}.join(', ')
	$stderr.puts "link.links.size:"
	$stderr.puts link.links.size
	$stderr.puts "next_links:"
	$stderr.puts next_links
	$stderr.puts next_links.size
      end
      raise "point is expected to be in link.links" unless next_links.size == 1
      point = link
      link = next_links.first
      @hops += 1
    end
    @to = link
    @from.add_edge(self)
  end
  def to_s
    "#{@from.to_s} - #{@to.to_s}. hops: #{@hops}"
  end
  def to_gpx(xml)
    xml.trkseg {
      from.to_gpx(xml)
      to.to_gpx(xml)
    }
  end
end

class Graph
  attr_reader :edges
  def initialize(p)
    # A Graph is seeded from one point, and grown out through all (transitively) connected edges:
    @edges = []
    add_edges_from_point(p)
  end
  def add_edges_from_point(p)
    p.edges.each {|e|
      unless @edges.include? e
	@edges << e
	add_edges_from_point(e.to)
      end
    }
  end
  def nodes
    (@edges.map {|e| e.from} + @edges.map {|e| e.to}).uniq
  end
  def to_s
    "GRAPH: #{@edges.map {|e| e}.join("\n")}"
    #"GRAPH:"
  end
  def to_gpx(xml)
    xml.trk {
      xml.name("graph")
      edges.each {|e|
	e.to_gpx(xml)
      }
    }
  end
end

class Network
  # A Network is the container for all of the waypionts read in from GPX files.
  # It has a Hash indexed by the lat/long of the waypoint so that points with identical lat/long
  # are regarded as being co-located, and can have links to 1, 2, 3,... more points 
  attr_reader :points, :edges, :graphs
  def initialize(gpx_files)
    @points = Hash.new {|h, k| h[k] = Point.new}
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
    @graphs = make_graphs
  end
  def to_gpx
    Nokogiri::XML::Builder.new {|xml|
      xml.gpx(xmlns: "http://www.topografix.com/GPX/1/1", version: "1.1") {
	graphs.each {|graph|
	  graph.to_gpx(xml)
	}
      }
    }.to_xml
  end
  def dump
    @points.keys.each {|k|
      puts "#{k} #{@points[k].link_count}"
    }
    puts graphs
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
    # Points that have exactly 2 links are in the middle of a 'chain' of points, 
    # so they are not the start of a DirectedEdge.
    # All other points are the start of a DirectedEdge:
    @points.values.find_all {|point| point.link_count != 2}.map {|point|
      # Create new DirectedEdge from p in the direction of link
      point.links.map{|link| DirectedEdge.new(point, link)}
    }.flatten
  end
  def make_graphs
    # returns an array of Graphs
    # Each member of the array is a complete list of connected edges
    graphs = []
    remaining_edges = edges
    # while there are still edges that have not been included in a Graph:
    while e = remaining_edges.first
      # Grow the graph to included all (transitively) connected edges
      graphs << Graph.new(e.from)
      remaining_edges = remaining_edges - graphs.last.edges
    end
    graphs
  end
end

nwk = Network.new(ARGV)
#puts nwk.graphs
puts nwk.to_gpx
$stderr.puts "WARNING: There are #{nwk.graphs.size} separate graphs - the routes/tracks are not fully connected" unless nwk.graphs.size == 1
#puts nwk.edges
