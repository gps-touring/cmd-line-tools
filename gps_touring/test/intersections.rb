require 'test/unit'
require 'gps_touring'

class Intersections < Test::Unit::TestCase
  def setup
    #puts "setup"
  end
  def teardown
    #puts "teardown"
  end
  def test1
    gpx_files = Dir.glob("intersections/network/simple.gpx")
    nwk = GpsTouring::Network.new(gpx_files)

  end
end
