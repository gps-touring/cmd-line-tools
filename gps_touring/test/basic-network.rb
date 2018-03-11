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
    gpx_files = Dir.glob("basic-network/network/*.gpx")
    nwk = GpsTouring::Network.new(gpx_files)

    assert_equal(2, nwk.logical_nodes.size, "Check number of logical nodes")
    assert_kind_of(GpsTouring::NetworkPoint, nwk.logical_nodes.first)
    assert_kind_of(GpsTouring::NetworkPoint, nwk.logical_nodes.last)

    assert_include(nwk.logical_nodes.map {|n| n.name}, "A")
    assert_include(nwk.logical_nodes.map {|n| n.name}, "C")

    a = nwk.logical_nodes.find {|n| n.name == "A"}
    assert(a)
    assert_kind_of(Float, a.lat)
    assert_kind_of(Float, a.lon)
    assert_kind_of(String, a.lat_s)
    assert_kind_of(String, a.lon_s)

    # Point A is linked only to one point:
    assert_equal(1, a.links.size)
    # ... whose name is B:
    assert_equal("B", a.links.first.name)
    b = a.links.first

    # There's just one GPX waypoint with the exact same lat/long as A:
    assert_equal(1, a.wpts.size)

    # The point that A is linked to is linked to 2 points:
    assert_equal(2, b.links.size)
    # NetworkPoint B was defined twice in the input GPX,
    # once at the end of a trkseg, and once at the start of the next trkseg.
    # So:
    assert_equal(2, b.wpts.size)

    assert_equal(3, nwk.points.size, "Check number of network points")
    assert_kind_of(GpsTouring::NetworkPoint, nwk.points.values.first)
    assert_kind_of(GpsTouring::NetworkPoint, nwk.points.values.last)
  end
  def test2
    assert( 2 == 2, "2 is 2")
  end
end
