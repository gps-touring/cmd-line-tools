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
    logical_nodes = nwk.logical_nodes
    puts "logical_nodes: #{logical_nodes.size}"
    puts "logical_graphs: #{nwk.logical_graphs.size}"
    assert_equal(1, nwk.logical_graphs.size, "Graph should be connected")

    pp logical_nodes.map {|n| n.name}
    assert_include(logical_nodes.map {|n| n.name}, "Cow Ark, Clitheroe", "Calling points should be logical nodes")
    assert_include(logical_nodes.map {|n| n.name}, "Newton-in-Bowland, Clitheroe", "Calling points should be logical nodes")
  end
end
