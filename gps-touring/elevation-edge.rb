
module GpsTouring
  class ElevationEdge
    attr_reader :from, :to, :first_link, :total_ascent, :total_descent, :distance_metres
    def initialize(point, link, ignore_diff = 2)
      @distance_metres = 0
      @ascent = 0
      @descent = 0
      @from = point
      @first_link = link
      @points = [point]
      ele = point.ele
      last_point_of_interest = point
      $stderr.puts ele
      state = :inc

      while link.link_count == 2
	@distance_metres += point.distance_m(link)
	next_ele = link.ele
	count = []
	if state == :inc
	  if next_ele > last_point_of_interest.ele
	    last_point_of_interest = link
	    count  << :a
	  end
	  if next_ele >= @points.last.ele + ignore_diff
	    @points << link
	    count  << :b
	  end
	  if next_ele <= last_point_of_interest.ele - ignore_diff
	    @points << last_point_of_interest unless @points.last === last_point_of_interest
	    @points << link
	    last_point_of_interest = link
	    state = :dec
	    count  << :c
	  end
	  raise("Bugger: #{count.to_s}") if count.size > 1 && count.include?(:c)
	else
	  if next_ele < last_point_of_interest.ele
	    last_point_of_interest = link
	  end
	  if next_ele <= @points.last.ele - ignore_diff
	    @points << link
	  end
	  if next_ele >= last_point_of_interest.ele + ignore_diff
	    @points << last_point_of_interest unless @points.last === last_point_of_interest
	    @points << link
	    last_point_of_interest = link
	    state = :inc
	  end
	end
	next_links = link.links - [point]
	raise "point is expected to be in link.links" unless next_links.size == 1
	point = link
	link = next_links.first
      end
      @to = link
      @points << link
      @from.add_elevation_edge(self)
      $stderr.puts @points.map {|p| "(#{p.lat}, #{p.lon}, #{p.ele})"}.join(", ")
    end
    def to_s
      "#{@from.to_s} - #{@to.to_s}. ascent: #{@ascent}; descent: #{@descent}; dist: #{distance_metres}m"
    end
    def to_gpx(xml)
      xml.trkseg {
	from.to_gpx(xml)
	to.to_gpx(xml)
      }
    end
  end
end
