require_relative 'network_points_array'

module GpsTouring
  class ElevationEdge
    include NetworkPointsArray
    attr_reader :points, :metres, :original_points
    def initialize(orig_pts, metres = 2)
      # Create an elevationEdge corresponding to the original points
      # Each point in the created ElevationEdge will be taken from  the
      # original set of NetworkPoints, but points with variations less than 'metres'
      # will be omitted. 
      @original_points = orig_pts
      @metres = metres
      @points = [orig_pts.first]
      orig_pts[1... orig_pts.size-1].each {|p|
	begin
	  if (p.ele - @points.last.ele).abs >= metres
	    @points << p
	  end
	rescue
	  # Points without ele return nil, but should be added anyway ...
	  if p.ele.nil? || @points.last.ele.nil?
	    @points << p
	  else
	    raise
	  end
	end
      }
      @points << orig_pts.last
      @points.freeze
    end
    def gpx_name
      name + " Smoothed out elevation diffs less than #{metres}m"
    end
  end
end
