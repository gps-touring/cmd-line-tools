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
      local_min = orig_pts.first
      local_max = orig_pts.first

      # We're either in the process of increasing or decreasing in elevation
      # - that's captured by the state variable.
      # Somewhat arbitrary initialization:
      state = orig_pts[1].ele > orig_pts[0].ele ? :inc : :dec

      orig_pts.each do |p|
	if state == :inc
	  if p.ele > local_max.ele
	    local_max = p
	    if p.ele >= @points.last.ele + metres
	      add_point(p)
	    end
	  elsif p.ele <= local_max.ele - metres
	    add_point(local_max) unless @points.last === local_max
	    add_point(p)
	    state = :dec
	    local_min = p
	  end
	else
	  if p.ele < local_min.ele
	    local_min = p
	    if p.ele <= @points.last.ele - metres
	      add_point(p)
	    end
	  elsif p.ele >= local_min.ele + metres
	    add_point(local_min) unless @points.last === local_min
	    add_point(p)
	    state = :inc
	    local_max = p
	  end
	end
      end
      add_point(orig_pts.last) unless @points.last === orig_pts.last 
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
