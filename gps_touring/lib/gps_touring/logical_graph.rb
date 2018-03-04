
module GpsTouring
  class LogicalGraph
    attr_reader :nodes, :edges
    #def initialize(p)
      ## A LogicalGraph is seeded from one point, and grown out through all (transitively) connected logical_edges:
      #@logical_edges = []
      #add_edges_from_point(p)
    #end
    def initialize(logical_node)
      @edges = []
      @nodes = []
      add_edges_from_node(logical_node)
    end
    def logical_edges
      $stderr.puts "Make LogicalGraph.logical_edges obsolete. use edges instead."
      @edges
    end
    def add_edges_from_node(node)
      unless @nodes.include? node
	@nodes << node
	node.links.each {|link|
	  @edges << LogicalEdge.new(node, link)
	  add_edges_from_node(@edges.last.to)
	}
      end
    end

    #def add_edges_from_point(p)
      #p.logical_edges.each {|e|
	#unless @logical_edges.include? e
	  #@logical_edges << e
	  #add_edges_from_point(e.to)
	#end
      #}
    #end
    #def nodes
      #(@logical_edges.map {|e| e.from} + @logical_edges.map {|e| e.to}).uniq
    #end
    def to_s
      "GRAPH: #{@logical_edges.map {|e| e}.join("\n")}"
      #"GRAPH:"
    end
    def to_gpx_trk(xml)
      xml.trk {
	xml.name("graph")
	logical_edges.each {|e|
	  e.to_gpx_trkseg(xml)
	}
      }
    end
  end
end
