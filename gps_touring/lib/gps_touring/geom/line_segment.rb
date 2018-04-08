module GpsTouring
  module Geom
    class LineSegment < Array	# Array of 2 points
      def initialize(p, q)
	super [p, q]
      end
      def as_s
	"#{first.as_s}-#{last.as_s}"
      end
    end
  end
end

