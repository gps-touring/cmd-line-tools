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
	assert_equal(o.points.size, o.cumm_distances.size,
		     "NetworkPointArray.cumm_distances shoue return a cumm distance for each point")
	o.cumm_distances.each_cons(2) {|pair|
	  assert(pair[0] <= pair[1], "Cummulative distances should be monotonic increasing")
	}
	assert(o.metres_up >= 0, "Metres up should be non-negative")
	assert(o.metres_down >= 0, "Metres down should be non-negative")
	assert_equal(e.points.size - 1, e.distances_between_points.size)
      }
    }
  end
end

