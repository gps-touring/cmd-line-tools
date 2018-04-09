require 'pp'
module GpsTouring
  # Geom::LineSegment is and Array of 2 points
  class LineSegment < Geom::LineSegment
    def initialize(p, q)
      super
      freeze
    end
    def create_links_between_points
      first.add_bidirectional_link(last)
    end
    def remove_links_between_points
      first.remove_bidirectional_link(last)
    end
    def name
      map {|p| p.name || "(#{p.y},#{p.x})"}.join('-')
    end
    def to_s
      "LineSegment from #{first.to_s} to #{last.to_s}"
    end
    def key
      sort {|a, b| [a.lat, a.lon] <=> [b.lat, b.lon]}.map {|p| p.geoloc}
    end
    def as_array_of_arrays
      map {|p| [p.x, p.y]}
    end
  end
  class LineSegments
    def initialize
      @h = Hash.new
    end
    def add(p, q)
      if p === q
	#$stderr.puts "LineSegment from #{p.to_s} to #{q.to_s} has identical endpoints - not adding"
      else
	ls = LineSegment.new(p, q)
	k = ls.key
	if @h.has_key?(k)
	  #$stderr.puts "LineSegment from #{p.to_s} to #{q.to_s} has already been added- not adding"
	else
	  @h[k] = ls
	  ls.create_links_between_points
	end
      end
    end
    def remove(line_segment)
      # May already 
      if @h.delete(line_segment.key)
	line_segment.remove_links_between_points
      end
      #k = line_segment.key
      #if @h.delete(k)
	#puts "Remove LineSegment #{k}"
	#line_segment.remove_links_between_points
      #else
	##pp @h.keys.sort
	#puts @h.keys.size
	#puts @h.keys.include?(k) ? k : 'not found'
	#raise "Attempting to delete non-existent LineSegment #{line_segment.to_s} with key #{k}"
      #end
    end
    def include?(line_segment)
      res = @h.has_key?(line_segment.key)
      unless res
	#puts @h.keys.sort.map {|k| k.to_s}.join("\n")

	v = @h.find {|k, v| v == line_segment}
	if v
	  puts "Value: #{v.inspect}"
	end
	puts "key: " + line_segment.key.to_s
      end
      res 
    end
    def all
      @h.values
    end
  end
end
