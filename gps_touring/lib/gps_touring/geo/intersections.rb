require 'pp'
module GpsTouring
  module Geo
    class LineSweep
      def initialize(line_segments)
	@events = line_segments.map {|seg|
	  if seg[0] == seg[1]
	    []
	  else
	    p, q = seg.sort {|a, b| a.x <=> b.x}
	    [ StartEvent.new(p, seg), EndEvent.new(q, seg) ]
	  end
	}.flatten.sort {|a, b| 
	  # ordinal is about making EndEvents come before StartEvents
	  [a.point.x, a.ordinal] <=> [b.point.x, b.ordinal]
	}
      end
      def each_event
	@events.each {|e|
	  yield e
	}
      end
      def each_start_event
	@events.each {|e|
	  if e.start_event?
	    yield e.line_segment
	  elsif e.end_event?
	  else
	    raise "Unknown event type"
	  end
	}
      end
      class Event
	# Each line segment has 2 events:
	# 1.When it 'starts'
	# 2.When it 'ends'
	attr_reader :point, :line_segment
	def initialize(point, line_segment)
	  @point, @line_segment = point, line_segment
	end
	def start_event?
	  is_a? StartEvent
	end
	def end_event?
	  is_a? EndEvent
	end
	def to_s
	  "#{type_s}\t#{point.x}\t#{point.y}\t#{line_segment.name}" 
	end
      end
      class StartEvent < Event
	def type_s
	  "START"
	end
	def ordinal
	  1	# EndEvents come before StrtEvents
	end
      end
      class EndEvent < Event
	def type_s
	  "END"
	end
	def ordinal
	  0	# EndEvents come before StrtEvents
	end
      end
    end
    def self.intersecting_line_segments(line_segments)
      # Returns an array of those line_segments that intersect
      # This does not include the case where two line segments
      # intersect at a point which is at the end of both line segments
      sweep = LineSweep.new(line_segments)

      # To implement a proper Line Sweep Alrorithm, see
      # http://page.mi.fu-berlin.de/panos/cg13/l03.pdf
      working_set = {}
      intersections = []
      sweep.each_event {|e|
	if e.start_event?
	  intersections.concat(intersections_with_set(e.line_segment, working_set.keys))
	  working_set[e.line_segment] = true
	elsif e.end_event?
	  working_set.delete(e.line_segment)
	else
	  raise "Unknown event type"
	end
	#puts e
	#pp working_set.keys.map {|ls| ls.name}
      }
      intersections
    end
    def self.intersections_with_set(line_seg, line_segs)
      line_segs.map { |b|
	res = Geom::line_segment_intersection(line_seg, b)
	if res
	  Geom::Intersection::new(line_seg, res.first, b, res.last)
	else
	  nil
	end
      }.compact
    end
    def self.intersection_ele(intersection)
      # intersection is a Geom::Intersection
      segs = intersection.line_segments
      p0, p1 = intersection.positions
      e00 = segs[0][0].ele
      e01 = segs[0][1].ele
      e10 = segs[1][0].ele
      e11 = segs[1][1].ele
      e0 = (e00 && e01 && (e00 + (e01 - e00)*p0)) || e00 || e01
      e1 = (e10 && e11 && (e10 + (e11 - e10)*p1)) || e10 || e11
      (e0 && e1 && ((p0 - 0.5).abs > (p1 - 0.5).abs ? e0 : e1 )) || e0 || e1
    end
  end
end


