require_relative "network_points_array"

module GpsTouring
  class LogicalEdge
    include NetworkPointsArray
    attr_reader :from, :to, :first_link, :hops, :logical_edge
    def initialize(point, link)
      @hops = 1
      @from = point
      @first_link = link
      @logical_edge = self
      while ! link.logical_node?
	unless link.links.include?(point)
	  $stderr.puts "point:"
	  $stderr.puts point
	  $stderr.puts "link:"
	  $stderr.puts link
	  $stderr.puts "link.links:"
	  $stderr.puts link.links.each{|x| $stderr.puts x}
	  $stderr.puts "link.links.size:"
	  $stderr.puts link.links.size
	  raise "point is expected to be in link.links"
	end
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
	raise "Unexpected branch - why wasn't this a logical_node?" unless next_links.size == 1
	point = link
	link = next_links.first
	@hops += 1
      end
      @to = link
      @from.add_edge(self)
    end
    def points
      [from, to]
    end
    def to_s
      "#{@from.to_s} - #{@to.to_s}. hops: #{@hops}"
    end
    def gpx_name
      name + " Logical Edge"
    end
  end
end
