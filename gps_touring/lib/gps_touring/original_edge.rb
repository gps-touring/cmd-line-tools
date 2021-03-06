require_relative "network_points_array"

# An OriginalEdge has all of the waypoints tagen from the originalGPX files.

module GpsTouring
  class OriginalEdge
    include NetworkPointsArray
    attr_reader :points
    def original_points
      @points
    end
    def initialize(points)
      @points = points
      freeze
    end
    def self.from_logical_edge(logical_edge)
      ###
      ### OBSOLETE
      ###
      raise "OriginalEdge.from_logical_edge is Obsolete! Use logical_edge.original_edge instead"
      point = logical_edge.from
      link = logical_edge.first_link
      points = [point]
      while link != logical_edge.to
	raise("Badly defined logicalEdge") unless link.links.size == 2

	points << link
	next_links = link.links - [point]

	raise "point is expected to be in link.links" unless next_links.size == 1

	point = link
	link = next_links.first
      end
      points << link

      raise("Expected to start at beginning of LogicalEdge") unless points.first === logical_edge.from
      raise("Expected to reach end of LogicalEdge") unless points.last === logical_edge.to
      new(points)
    end
    def gpx_name
      name + " Original GPX waypoints"
    end
  end
end


