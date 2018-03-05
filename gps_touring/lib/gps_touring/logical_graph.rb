
module GpsTouring
  class LogicalGraph
    attr_reader :nodes, :edges, :acyclic_paths, :edges_from_node
    def initialize(logical_node, node_test)
      @edges = []
      @nodes = []
      add_edges_from_node(logical_node, node_test)

      # Map from  node to array of edges leading from that node:
      @edges_from_node = Hash[nodes.map {|n| 
	[n, edges.find_all {|e| e.from === n}]
      }]

      # All paths through the graph that don't visit the same node twice.
      # A path is a sequence of edges
      @acyclic_paths = edges.map {|e| grow([e]) }.
	inject([], :+).
	map {|p| Path.new(p)}


    end
    def paths(from, to)
      acyclic_paths.find_all {|p|
	p.first.from == from && p.last.to == to
      }
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
    def grow(eseq)
      # Returns an array of all of the acyclic paths that start with eseq
      # including eseq itself

      # We need to know which nodes we've already visited in the
      # sequence of LogicalEdges called eseq:
      already_visited = eseq.map {|e| e.from}

      # Which edges lead on from  the end of eseq:
      next_edges = @edges_from_node[eseq.last.to]

      # We're going to return the sequence of edges eseq ... 
      res = [eseq]

      # plus all of the sequneces that can be grown onto eseq
      # without visiting the same node twice:
      next_edges.
	reject{|e| already_visited.include? e.to}.
	each {|e| res += grow(eseq + [e]) }

      res
    end

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
