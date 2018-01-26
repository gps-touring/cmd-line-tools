require_relative "network-points-array"

module GpsTouring
  class ElevationEdge
    include NetworkPointsArray
    # TODO delete this ascent/descent/dist shite from here, and move it to methods of NetworkPointsArray
    attr_reader :logical_edge, :points, :total_ascent, :total_descent, :distance_metres
    def initialize(logical_edge, metres = 2)
      point = logical_edge.from
      link = logical_edge.first_link
      @logical_edge = logical_edge
      @distance_metres = 0
      @ascent = 0
      @descent = 0
      @points = [point]
      ele = point.ele
      last_point_of_interest = point
      #$stderr.puts ele
      state = :inc

      while link.link_count == 2
	@distance_metres += point.distance_m(link)
	next_ele = link.ele
	#count = []
	if state == :inc
	  if next_ele > last_point_of_interest.ele
	    last_point_of_interest = link
	    #count  << :a
	  end
	  if next_ele >= @points.last.ele + metres
	    add_point(link)
	    #count  << :b
	  end
	  if next_ele <= last_point_of_interest.ele - metres
	    add_point(last_point_of_interest) unless @points.last === last_point_of_interest
	    add_point(link)
	    last_point_of_interest = link
	    state = :dec
	    #count  << :c
	  end
	  #raise("Bugger: #{count.to_s}") if count.size > 1 && count.include?(:c)
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
      @points << link
      #@from.add_elevation_edge(self)
      #$stderr.puts @points.map {|p| "(#{p.lat}, #{p.lon}, #{p.ele})"}.join(", ")
    end
    def add_point(p)
      raise("Algotithm error: adding same point twice in a row to an ElevationEdge") if p === @points.last
      if p.ele > @points.last.ele
	@ascent += p.ele - @points.last.ele
      else
	@descent += @points.last.ele - p.ele
      end
      @points << p
    end
    def to_s
      "#{@logical_edge.from.to_s} - #{@logical_edge.to.to_s}. ascent: #{@ascent}; descent: #{@descent}; dist: #{distance_metres}m"
    end
    #def to_gpx(xml)
      #raise("to_gpx Needs modifying for ElevationEdge!")
      #xml.trkseg {
	#logical_edge.from.to_gpx(xml)
	#logical_edge.to.to_gpx(xml)
      #}
    #end
  end
end
