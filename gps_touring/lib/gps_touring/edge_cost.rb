module GpsTouring
  module EdgeCost
    def self.by_distance_only
      lambda {|e|
	orig = GpsTouring::OriginalEdge.new(e)
	orig.metres_distance
      }
    end
    def self.by_ascent_only
      lambda {|e|
	orig = GpsTouring::OriginalEdge.new(e)
	orig.metres_up
      }
    end
  end
end

