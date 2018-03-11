require 'test/unit'
require 'pp'
require 'gps_touring'

class AllNetworks < Test::Unit::TestCase

  def setup
    @nwk_dirs = Dir.glob("*/network/")
  end
  def teardown
    #puts "teardown"
  end
  def test1
    @nwk_dirs.each {|dir|
      gpx_files = Dir.glob("#{dir}*.gpx")
      pp gpx_files
      nwk = GpsTouring::Network.new(gpx_files)
      nwk.logical_edges.each {|e|
	o = e.original_edge
	assert_equal(o.points, o.elevation_edge(0).points)
      }
    }
  end
end

