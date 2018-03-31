
# A Path is a sequence of connected LogicalEdges
# which never visit the same LogicalNode twice.
# TODO - verify that this means that a Path never visits 
# the same NetworkPoint twice

module GpsTouring
  class Path < Array	# Array members are LogicalEdges
    # To make avilable the methods from NetworkPointsArray,
    # we need to define the instance method: #points
    include NetworkPointsArray
    attr_reader :points, :original_points

    def initialize(edges)
      # A Path is an Array (i.e. sequence) of edges
      concat edges
      @points = map {|e| e.original_edge.points}.inject([], :+)
      @original_points = map {|e| e.original_edge.original_points}.inject([], :+)
      freeze
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
    def to_gpx_name(xml)
      xml.name name
    end
    def name
      "#{first.from.name} - #{last.to.name}"
    end
#    def group_by_nodes(nodes)
#      # Returns an array of arrays of edges such that
#      # for each member array A,
#      #   A[i].from belongs to nodes if and only if A[i] is A.first
#      #   A[i].to   belongs to nodes if and only if A[i] is A.last
#      # This is useful for paritioning a Path by calling points
#      raise "Bad params to Path.group_path" unless nodes.include? first.from
#      raise "Bad params to Path.group_path" unless nodes.include? last.to
#      chunk_while {|e, f| ! nodes.include? e.to}.to_a
#    end
  end
end

