require 'test/unit'
require 'pp'
require 'gps_touring'

class BasicRouteFinding < Test::Unit::TestCase
  attr_reader :nwk
  def setup
    gpx_files = Dir.glob("basic-route-finding/*.gpx")
    @nwk = GpsTouring::Network.new(gpx_files)
  end
  def teardown
    #puts "teardown"
  end
  def test1
    calling_network_points = nwk.set_calling_points("basic-route-finding/calling-points.gpx")
    File.open("basic-route-finding/output/logical-graph.gpx", "w") {|f| f.write(nwk.logical_graphs_gpx)}
    logical_nodes = nwk.logical_nodes
    puts "logical_nodes: #{logical_nodes.size}"
    #puts logical_nodes.map {|n|
      #"Logical Node #{n.class}: #{n.object_id}\n" + n.to_s
    #}.join("\n")
    #puts "logical_graphs: #{nwk.logical_graphs.size}"
    assert_equal(1, nwk.logical_graphs.size, "Graph should be connected")

    nwk.logical_graphs.each {|g|
      g.edges_from_node.each{|n, es|
	es.each{|e|
	  assert_equal(n, e.from, "Edges from a node have their from attriute set to that same node")
	}
      }
      puts "acyclic_paths: #{g.acyclic_paths.size}"
      puts "nodes: #{g.nodes.size}"
      puts "edges: #{g.edges.size}"

      #pp g.acyclic_paths.map{|p| p.map {|e| e.object_id}}
      g.acyclic_paths.each {|p|
	(0...p.size-1).each {|i|
	  assert_equal(p[i].to, p[i+1].from, "Sequences of edges in a path form a connected chain")
	}
      }
      paths = g.acyclic_paths
      assert_equal(paths.size, paths.map{|p| p.map{|e| e.object_id}}.sort.uniq.size, "No duplicate paths")
    }


    #pp logical_nodes.map {|n| n.name}
    assert_include(logical_nodes.map {|n| n.name}, "Cow Ark, Clitheroe", "Calling points should be logical nodes")
    assert_include(logical_nodes.map {|n| n.name}, "Newton-in-Bowland, Clitheroe", "Calling points should be logical nodes")

    edge_cost_method = GpsTouring::EdgeCost.by_distance_only
    #edge_cost_method = GpsTouring::EdgeCost.by_ascent_only
    route = nwk.find_route(calling_network_points, edge_cost_method)
    route.each {|es|
      es.each {|e|
	assert_instance_of(GpsTouring::LogicalEdge, e)
      }
    }
    File.open("basic-route-finding/output/route.gpx", "w") {|f| 
      f.write(route.to_gpx)
    }
  end
end
