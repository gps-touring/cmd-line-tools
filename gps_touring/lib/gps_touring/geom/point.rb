
module GpsTouring
  module Geom
    class Point
      attr_accessor :x, :y
      def initialize(x, y)
	@x, @y = x.to_f, y.to_f
      end
      def cross(w)
	x * w.y - y * w.x
      end
      def -(w)
	Point::new(x - w.x, y - w.y)
      end
      def +(w)
	Point::new(x + w.x, y + w.y)
      end
      def *(n)	# scalar multimplication
	Point::new(x*n, y*n)
      end
      def /(n)
	Point::new(x/n, y/n)
      end
      #def ==(w)
	#raise "check"
	#x == w.x && y == w.y
      #end
      def as_s
	"(#{x}, #{y})"
      end
    end
  end
end
