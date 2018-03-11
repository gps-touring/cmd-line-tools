# A route is a sequence of paths.
# For example there may be one sequence of paths between each pair of calling points
# Whereas a Path may not visit the same LogicalNode twice,
# a route may do so.


module GpsTouring
  class Route < Array # Array members are Paths
    include NetworkPointsArray
    def initialize(graph, calling_points, edge_cost_method)
      # pre-calculate edge costs for each edge, to save
      # costly repetitive calculations:
      edge_cost = Hash[graph.edges.map {|e| 
	[e, edge_cost_method.call(e)]
      }]

      concat (0...calling_points.size-1).map {|i|
	from = calling_points[i]
	to = calling_points[i+1]
	cheapest_path = graph.paths(from, to).map {|p|
	  [p, p.cost(edge_cost)]
	}.
	# Sort by ascending cost
	sort {|a, b| a.last <=> b.last}.
	# Get cheapest [path, cost] array
	first.
	# Get just the path:
	first
      }
    end
    def points
      map {|path| path.points}.inject([], :+)
    end
    def to_gpx
      GPX::Builder.new {|xml|
	each {|path|
	  xml.trk {
	    path.to_gpx_name(xml)
	    path.each {|e|
	      orig = OriginalEdge.new(e)
	      #puts "Path - Orig points: #{orig.points.size}"

	      orig.to_gpx_trkseg(xml)
	    }
	  }
	}
      }.to_xml
    end
  end
end
