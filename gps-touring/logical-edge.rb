require_relative "network-points-array"

module GpsTouring
  class LogicalEdge
    include NetworkPointsArray
    attr_reader :from, :to, :first_link, :hops, :logical_edge
    def initialize(point, link, logical_nodes)
      @hops = 1
      @from = point
      @first_link = link
      @logical_edge = self
      #while link.link_count == 2
      #while !logical_nodes.include? link
      while ! link.logical_node?
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
