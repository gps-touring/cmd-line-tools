
module GpsTouring
  class LogicalGraph
    attr_reader :nodes, :edges
    def initialize(logical_node, node_test)
      @edges = []
      @nodes = []
      add_edges_from_node(logical_node, node_test)
    end
    def to_s
      "GRAPH: #{@edges.map {|e| e}.join("\n")}"
    end
    def to_gpx_trk(xml)
      xml.trk {
	xml.name("graph")
	edges.each {|e|
	  e.to_gpx_trkseg(xml)
	}
      }
    end
    private
    def add_edges_from_node(node, node_test)
      unless @nodes.include? node
	@nodes << node
	node.links.each {|link|
	  @edges << LogicalEdge.new(node, link, node_test)
	  # And recurse ...
	  add_edges_from_node(@edges.last.to, node_test)
	}
      end
    end

  end
end
