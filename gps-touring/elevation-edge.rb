require_relative "network-points-array"

module GpsTouring
  class ElevationEdge
    include NetworkPointsArray
    attr_reader :logical_edge, :points
    def initialize(logical_edge, metres = 2)
      point = logical_edge.from
      link = logical_edge.first_link
      @logical_edge = logical_edge
      @points = [point]
      #$stderr.puts point
      ele = point.ele
      last_point_of_interest = point
      #$stderr.puts ele
      # Somewhat arbitrary initialization:
      state = link.ele > point.ele ? :inc : :dec

      while link.link_count == 2
	next_ele = link.ele
	if state == :inc
	  if next_ele > last_point_of_interest.ele
	    last_point_of_interest = link
	  end
	  if next_ele >= @points.last.ele + metres
	    add_point(link)
	  end
	  if next_ele <= last_point_of_interest.ele - metres
	    add_point(last_point_of_interest) unless @points.last === last_point_of_interest
	    add_point(link)
	    last_point_of_interest = link
	    state = :dec
	  end
	else
	  if next_ele < last_point_of_interest.ele
	    last_point_of_interest = link
	  end
	  if next_ele <= @points.last.ele - metres
	    add_point(link)
	  end
	  if next_ele >= last_point_of_interest.ele + metres
	    add_point(last_point_of_interest) unless @points.last === last_point_of_interest
	    add_point(link)
	    last_point_of_interest = link
	    state = :inc
	  end
	end
	next_links = link.links - [point]
	raise "point is expected to be in link.links" unless next_links.size == 1
	point = link
	link = next_links.first
      end
      add_point(link)
      @points.freeze
      raise("Expected to start at beginning of LogicalEdge") unless @points.first === logical_edge.from
      raise("Expected to reach end of LogicalEdge") unless link === logical_edge.to
      #$stderr.puts @points.map {|p| "(#{p.lat}, #{p.lon}, #{p.ele})"}.join(", ")
    end
    def add_point(p)
      raise("Algotithm error: adding same point twice in a row to an ElevationEdge") if p === @points.last
      @points << p
    end
    def to_s
      "#{@logical_edge.from.to_s} - #{@logical_edge.to.to_s}. ascent: tbd; descent: tbd; dist: tbd"
    end
  end
end
