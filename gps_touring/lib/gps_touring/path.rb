
# A Path is a sequence of connected LogicalEdges
# which never visit the same LogicalNode twice
#

module GpsTouring
  class Path < Array
    def initialize(edges)
      # A Path is an Array (i.e. sequence) of edges
      concat edges
    end
    def cost(edge_cost)
      map {|e| edge_cost[e]}.inject(0, :+)
    end
    def to_gpx
      GPX::Builder.new {|xml|
	xml.trk {
	  xml.name("Path")
	  each {|e|
	    orig = OriginalEdge.new(e)
	    #puts "Path - Orig points: #{orig.points.size}"

	    orig.to_gpx_trkseg(xml)
	  }
	}
      }.to_xml
    end
  end
end
