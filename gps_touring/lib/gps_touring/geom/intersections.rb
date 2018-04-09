module GpsTouring
  module Geom
    class Intersection
      def initialize(ls1, r1, ls2, r2)
	@ls1, @r1, @ls2, @r2 = ls1, r1, ls2, r2
	freeze

	# Check to n significant digits:
	n = 9
	fs = "%.#{n}g"	# format string
	i = @ls1[0] + (@ls1[1] - @ls1[0])*@r1
	j = @ls2[0] + (@ls2[1] - @ls2[0])*@r2
	raise "Ill-defined intersection: these should be the same: #{i.as_s}, #{j.as_s}\nls1: #{ls1.as_s}; ls2: #{ls2.as_s}; r1: #{@r1}; r2: #{@r2}" unless fs % i.x == fs % j.x && fs % i.y == fs % j.y
      end
      def point
	@ls1[0] + (@ls1[1] - @ls1[0])*@r1
      end
      def line_segments
	[@ls1, @ls2]
      end
      def positions	# between 0 and 1
	[@r1, @r2]
      end
    end
    def self.line_segment_intersection(a, b)
      # a, b are Geom::LineSegments
      # returns Geom::Point of intersection, or nil if none

      # See https://stackoverflow.com/a/565282
      p = a[0]
      r = a[1] - p
      q = b[0]
      s = b[1] - q

      numerator = (q - p).cross(s)
      denominator = r.cross(s)

      if denominator == 0
	if numerator == 0
	  # line segments are colinear. 
	  #puts "COLINEAR"
	  if a[1].x != a[0].x
	    return one_d_intersection(a[0].x, a[1].x, b[0].x, b[1].x)
	  elsif a[1].y != a[0].y
	    return one_d_intersection(a[0].y, a[1].y, b[0].y, b[1].y)
	  else
	    # ignore line segment a - it has zero length
	    nil
	  end
	else
	  # lines are parallel and non-intersecting
	  #puts "Parallel"
	  nil
	end
      else
	t = numerator/denominator
	# change < to <= if you want to include common ends
	if 0 < t && t < 1
	  u = (p - q).cross(r)/(-denominator)
	  # change < to <= if you want to include common ends
	  if 0 < u && u < 1
	    # INTERSECTION!
	    #puts "intersection: #{a.as_s} at #{t} with #{b.as_s} at #{u}" 
	    return [t, u]
	  else
	    nil
	  end
	else
	  #puts "Non intersecting"
	  nil
	end
      end
      nil
    end
    def self.one_d_intersection(a0, a1, b0, b1)
      t = (b0 - a0)/(a1 - a0)
      u = (b1 - a0)/(a1 - a0)
      m = [0, [t, u].min].max
      n = [1, [t, u].max].min
      # We choose a point of intersection in the middle of the overlap
      # k is proportional dist of intersection from point a0 to point a1
      k = (m + n)/2.0
      # change < to <= if you want to include common ends
      if 0 < k && k < 1
	# h is proportional dist of intersection from point b0 to point b1
	h = (a0 + k*(a1 - a0) - b0)/(b1 - b0) 
	#puts "Coeff of coincidence: #{k}, #{h}"
	return [k, h]
      else
	#puts "No overlap, k = #{k}"
	return nil
      end
    end
  end
end

