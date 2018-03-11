require_relative "network_points_array"

module GpsTouring
  class LogicalEdge
    include NetworkPointsArray
    attr_reader :from, :to, :first_link, :hops
    def initialize(point, link, node_test)
      @hops = 1
      @from = point
      @first_link = link
      # Keep following the next link until we hit another Node
      # (based on calling node_test):
      while ! node_test.call(link)
	unless link.links.include?(point)
	  $stderr.puts "point:"
	  $stderr.puts point
	  $stderr.puts "link:"
	  $stderr.puts link
	  $stderr.puts "link.links:"
	  $stderr.puts link.links.each{|x| $stderr.puts x}
	  $stderr.puts "link.links.size:"
	  $stderr.puts link.links.size
	  raise "Software bug: Found link between NetworkPoints that is not bidirectional"
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
	  raise "Calling error: point #{link} should be a logical node because it does not provide just one onward link to follow"
	end
	point = link
	link = next_links.first
	@hops += 1
      end
      @to = link
    end
    def points
      [from, to]
    end
    def original_edge
      OriginalEdge.new(self)
    end
    def to_s
      "#{@from.to_s} - #{@to.to_s}. hops: #{@hops}"
    end

    def gpx_name
      name + " Logical Edge"
    end
  end
end
