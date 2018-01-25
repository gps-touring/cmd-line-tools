
module GpsTouring
  class LogicalEdge
    attr_reader :from, :to, :hops, :distance_metres
    def initialize(point, link)
      @hops = 1
      @distance_metres = 0
      @from = point
      while link.link_count == 2
	@distance_metres += point.distance_m(link)
	next_links = link.links - [point]
	unless next_links.size == 1
	  $stderr.puts "point:"
	  $stderr.puts point
	  $stderr.puts "link:"
	  $stderr.puts link
	  $stderr.puts "link.links:"
	  $stderr.puts link.links.map{|x| x.object_id}.join(', ')
	  $stderr.puts "link.links.size:"
	  $stderr.puts link.links.size
	  $stderr.puts "next_links:"
	  $stderr.puts next_links
	  $stderr.puts next_links.size
	end
	raise "point is expected to be in link.links" unless next_links.size == 1
	point = link
	link = next_links.first
	@hops += 1
      end
      @to = link
      @from.add_edge(self)
    end
    def to_s
      "#{@from.to_s} - #{@to.to_s}. hops: #{@hops}; dist: #{distance_metres}m"
    end
    def to_gpx(xml)
      xml.trkseg {
	from.to_gpx(xml)
	to.to_gpx(xml)
      }
    end
  end
end
