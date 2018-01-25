
module GpsTouring
  class LogicalGraph
    attr_reader :edges
    def initialize(p)
      # A LogicalGraph is seeded from one point, and grown out through all (transitively) connected edges:
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
end
