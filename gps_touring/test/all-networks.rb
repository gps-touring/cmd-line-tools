require 'test/unit'
require 'pp'
require 'gps_touring'

class AllNetworks < Test::Unit::TestCase

  def setup
    # Get a list  of all dirs called 'network' within 
    # the subdirs where TestCases are defined:
    @nwk_dirs = Dir.glob("*/network/")
  end
  def teardown
    #puts "teardown"
  end
  def test1
    @nwk_dirs.each {|dir|
      gpx_files = Dir.glob("#{dir}*.gpx")
      nwk = GpsTouring::Network.new(gpx_files)
      nwk.logical_edges.each {|e|
	o = e.original_edge
	assert_equal(o.points, o.elevation_edge(0).points,
		    "Smoothing by 0 metres should do nothing")
      }
    }
  end
end

