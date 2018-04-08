
module GpsTouring
  # Geom::LineSegment is and Array of 2 points
  class LineSegment < Geom::LineSegment
    def initialize(p, q)
      p.add_bidirectional_link(q)
      super
    end
    def name
      map {|p| p.name || "(#{p.y},#{p.x})"}.join('-')
    end
    def as_array_of_arrays
      map {|p| [p.x, p.y]}
    end
  end
  class LineSegments < Array
    def add(p, q)
      push(LineSegment.new(p, q))
    end
  end
end
