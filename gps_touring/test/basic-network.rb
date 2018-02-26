require 'test/unit'
require 'gps_touring'

class BasicNetwork < Test::Unit::TestCase
  def setup
    #puts "setup"
  end
  def teardown
    #puts "teardown"
  end
  def test1
    nwk = GpsTouring::Network.new(["basic-network/route.gpx"])

    assert_equal(2, nwk.logical_nodes.size, "Check number of logical nodes")
    assert_kind_of(GpsTouring::NetworkPoint, nwk.logical_nodes.first)
    assert_kind_of(GpsTouring::NetworkPoint, nwk.logical_nodes.last)

    assert_equal(3, nwk.points.size, "Check number of network points")
    assert_kind_of(GpsTouring::NetworkPoint, nwk.points.values.first)
    assert_kind_of(GpsTouring::NetworkPoint, nwk.points.values.last)
  end
  def test2
    assert( 2 == 2, "2 is 2")
    assert( 1 == 2, "2 is 2")
    puts "After failure"
    assert( 3 == 3, "3 is 3")
  end
end
