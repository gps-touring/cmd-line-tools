
module GpsTouring
  class LogicalGraph
    attr_reader :logical_edges
    def initialize(p)
      # A LogicalGraph is seeded from one point, and grown out through all (transitively) connected logical_edges:
      @logical_edges = []
      add_edges_from_point(p)
    end
    def add_edges_from_point(p)
      p.logical_edges.each {|e|
	unless @logical_edges.include? e
	  @logical_edges << e
	  add_edges_from_point(e.to)
	end
      }
    end
    def nodes
      (@logical_edges.map {|e| e.from} + @logical_edges.map {|e| e.to}).uniq
    end
    def to_s
      "GRAPH: #{@logical_edges.map {|e| e}.join("\n")}"
      #"GRAPH:"
    end
    def to_gpx(xml)
      xml.trk {
	xml.name("graph")
	logical_edges.each {|e|
	  e.to_gpx(xml)
	}
      }
    end
  end
end
