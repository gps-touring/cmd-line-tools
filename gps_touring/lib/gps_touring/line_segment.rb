
module GpsTouring
  class LineSegment
    def initialize(p, q)
      p.add_bidirectional_link(q)
    end
  end
  class LineSegments < Array
    def add(p, q)
      push(LineSegment.new(p, q))
    end
  end
end
