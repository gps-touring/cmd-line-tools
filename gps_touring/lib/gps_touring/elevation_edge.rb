require_relative 'network_points_array'

module GpsTouring
  class ElevationEdge
    include NetworkPointsArray
    attr_reader :points, :metres
    def initialize(orig_pts, metres = 2)
      # Create an elevationEdge corresponding to the original points
      # Each point in the created ElevationEdge will be taken from  the
      # original set of NetworkPoints, but points with variations less than 'metres'
      # will be omitted. 
      @metres = metres
      @points = [orig_pts.first]
      orig_pts[1... orig_pts.size-1].each {|p|
	if (p.ele - @points.last.ele).abs >= metres
	  @points << p
	end
      }
      @points << orig_pts.last
      @points.freeze
    end
    def gpx_name
      name + " Smoothed out elevation diffs less than #{metres}m"
    end
    private
    def add_point(p)
      raise("Algotithm error: adding same point twice in a row to an ElevationEdge: #{p}") if p === @points.last
      @points << p
    end
  end
end
