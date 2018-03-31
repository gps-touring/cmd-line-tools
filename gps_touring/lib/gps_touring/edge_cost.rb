module GpsTouring
  module EdgeCost
    def self.by_distance_only
      lambda {|e|
	e.original_edge.metres_distance
      }
    end
    def self.by_ascent_only
      lambda {|e|
	e.original_edge.metres_up
      }
    end
  end
end

