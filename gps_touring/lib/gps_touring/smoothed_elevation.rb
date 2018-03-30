require 'pp'
require_relative 'network_points_array'

module GpsTouring
  class SmoothedElevation
    include NetworkPointsArray
    attr_reader :points, :metres
    def original_points
      @original_point_seq.points
    end
    def initialize(point_seq, metres = 100)
      # Create an SmoothedElevation corresponding to the original points
      # Each point in the created SmoothedElevation will have it's elevation set
      # to a (weighted) average of the points around it.
      # The number of points is the same as the number of orig_points.
      @original_point_seq = point_seq
      @metres = metres
      cumm_dists = point_seq.cumm_distances
      #pp cumm_dists
      @points = point_seq.points.each_with_index.map {|p, i|
	q = p.clone

	# Find the range [mini, maxi] of indexes into the point_seq.points array
	# that describes the points we need for calculating the weighted average
	mini = i
	begin
	while mini > 0 && (cumm_dists[i] - cumm_dists[mini]) < metres
	  mini -= 1
	end
	rescue
	  puts i, mini, cumm_dists.size
	  puts cumm_dists[i]
	  puts cumm_dists[mini]
	  raise
	end
	max = cumm_dists.size - 1
	maxi = i
	while maxi < max - 1 && cumm_dists[maxi] - cumm_dists[i] < metres
	  maxi += 1
	end

	# We create an array of pairs,
	# each pair is [distance from i, elevation]

	raise "Bad mini #{mini}" unless mini >= 0
	raise "Bad maxi #{maxi}" unless maxi < point_seq.points.size
	#puts "mini, maxi: #{mini}, #{maxi}"
	dist_ele_array = (mini...maxi).map {|j| 
	  [(cumm_dists[i] - cumm_dists[j]).abs, point_seq.points[j].ele]
	}.
	# Remove all elements with nil ele:
	reject {|de| de[1].nil? }

	if dist_ele_array[0][0] > metres
	  raise "Bad algorithm" if dist_ele_array[1][0] > metres	# alogorithm failure
	  dist_ele_array[0][1] = interpolate(*dist_ele_array[0], *dist_ele_array[1], metres)
	  dist_ele_array[0][0] = metres
	end

	if dist_ele_array.last[0] > metres
	  raise "Bad algorithm" if dist_ele_array[-1][0] < metres	# alogorithm failure
	  dist_ele_array.last[1] = interpolate(*dist_ele_array.last, *dist_ele_array[-1], metres)
	  dist_ele_array.last[0] = metres
	end

	# First stab is to ise an unweighted average:
	new_ele = dist_ele_array.map {|z| z[1]}.inject(0, :+) / dist_ele_array.size.to_f

	q.ele = new_ele
	q
      }
      @points.freeze
    end
    def interpolate(x1, y1, x2, y2, x)
      #raise "bad params to interpolate" unless (x1 <= x && x <= x2)
      res = y1 + (y2 - y1)*(x - x1)/(x2 - x1).to_f
      if res.nan?
	puts "interpolate returning NaN. #{x1}, #{y1}, #{x2}, #{y2}, #{x}"
      end
      res
    end
    def gpx_name
      name + " Smoothed out elevation diffs less than #{metres}m"
    end
  end
end
