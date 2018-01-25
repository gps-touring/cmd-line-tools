module GpsTouring
  class NetworkPoint
    TORADIANS = Math::PI / 180;
    R = 6371000; # metres
    attr_reader :links, :logical_edges
    def initialize
      # wpts are all of the GPX waypoints (objects from Nokogiri) which have lat/lon that exactly match this NetworkPoint
      @wpts = []

      # links are NetworkPoints reachable by a single hop 
      # i.e. adjacent <rtept> or <trkpt> elements in the <rte> or <trkseg> gps data:
      @links = []

      # logical_edges are defined only for Points that are at the end of a sequence of points, 
      # or those that are at a junction.
      # In other words, never if links.size == 2 (which means the point is in the interior of a route, one link goes backwards, the other forewards)
      @logical_edges = []
    end
    def sanity_check
      # Check invariants
      [
	# If this point is not linked to exactly 2 others, then logical edges start from here:
	link_count == 2 || @logical_edges.size > 0,

	# If this point is not linked to exactly 2 others, then theres a logical edge for each point linked to:
	link_count == 2 || @links.size == @logical_edges.size,

	# If this point is linked to exactly 2 others, then no logical edges start here:
	link_count != 2 || @logical_edges.size == 0,

	# If no logical edge starts here, then this point links to exactly 2 others:
	@logical_edges != 0 || link_count == 2,

	# All GPX waypoints for this point have identical lat and lon:
	@wpts.map{|w| [w['lat'], w['lon']]}.uniq.size == 1,

	# All points linked to have different lat/long:
	@links.size == @links.map {|p| p.geoloc}.uniq.size

      ].each_with_index {|success, index|
	raise "Invariant[#{index}] failed (index starts at 0)" unless success
      }
    end
    def distance_m(p)
      # Distance in metres
      # Uses Haversine - more accurate over short distances.
      selfLatRad = self.lat.to_f * TORADIANS;
      pLatRad = p.lat.to_f * TORADIANS;
      latDiffRad = (p.lat.to_f - self.lat.to_f) * TORADIANS;
      lonDiffRad = (p.lon.to_f - self.lon.to_f) * TORADIANS;

      a = Math.sin(latDiffRad / 2) * Math.sin(latDiffRad / 2) +
	Math.cos(selfLatRad) * Math.cos(pLatRad) *
	Math.sin(lonDiffRad / 2) * Math.sin(lonDiffRad / 2);
      c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

      return R * c;
    end
    def add_wpt(wpt)
      @wpts << wpt
    end
    def add_link_to(p)
      return if p === self
      # p will already be in @links if there is a sequence of waypoints like this:
      # p, q, p
      # and here we would have self == q
      # In this case q must be treated as the end of an edge - i.e. it will have just one link.
      @links << p unless @links.include?(p)
    end
    def add_edge(e)
      e.from === self || raise("Bug - expected all logical_edges are from this point")
      @logical_edges << e
    end
    def link_count
      @links.size
    end
    def to_s
      @wpts.first.to_s
    end
    def lat
      @wpts.first['lat']
    end
    def lon
      @wpts.first['lon']
    end
    def geoloc
      [lat, lon]
    end
    def to_gpx(xml)
      xml.trkpt(lat: lat, lon: lon) {
	name = @wpts.map {|w| n = w.at_css('name'); n || nil}.compact
	unless name.empty?
	  xml.name(name.join('|'))
	end
      }
    end
  end
end

