module GpsTouring
  class NetworkPoint
    TORADIANS = Math::PI / 180;
    R = 6371000; # metres
    attr_reader :links, :logical_edges, :calling_point
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

      @calling_point = false
    end
    def sanity_check
      # Check invariants
      [
	# If this point is not linked to exactly 2 others, then logical edges start from here:
	link_count == 2 || @logical_edges.size > 0,

	# If this point is not linked to exactly 2 others, then theres a logical edge for each point linked to:
	link_count == 2 || @links.size == @logical_edges.size,

	# If this point is linked to exactly 2 others, then no logical edges start here, unless it is a calling_point:
	link_count != 2 || (@logical_edges.size == 0 || @calling_point),

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
    def logical_node?
      @calling_point || link_count != 2
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
    def to_point_array(link, to)
      $stderr.puts "NetworkPoint#to_point_array - method untested!"
      # Creates an array of points from this point up to and including the point 'to', 
      # the first step is taken to the point 'link'
      raise("Usage error - link param is bad") unless links.include?(link)
      points = [self, link]
      prev = self
      while link != to
	onward_links = link.links - [prev]
	raise("Usage error - to_point_array called inappropriately") unless onward_links.size == 1
	prev = link
	link = onward_links.first
	points << link
      end
      points
    end
    def add_wpt(wpt)
      @wpts << wpt
      self
    end
    def add_calling_point(wpt)
      # if this NetworkPoint currently has no wpts, then it has been freshly
      # created for this calling point.
      @wpts << wpt
      @calling_point = true
      self
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
      @lat ||= @wpts.first['lat']
    end
    def lon
      @lon ||= @wpts.first['lon']
    end
    def ele
      return @ele if defined? @ele
      @ele = @wpts.map {|wpt| wpt.at_css('ele')}.compact.map{|s| s.text.to_f}.first || 0.0
    end
    def name
      return @name if defined? @name
      names = @wpts.map {|w| n = w.at_css('name'); n || nil}.compact
      @name = names.empty? ? nil : names.join('|')
    end
    def geoloc
      [lat, lon]
    end
    def to_gpx_trkpt(xml)
      xml.trkpt(lat: lat, lon: lon) {
	xml.name(name) if name
	xml.ele(ele)
      }
    end
    def to_gpx_rtept(xml)
      xml.rtept(lat: lat, lon: lon) {
	xml.name(name) if name
	xml.ele(ele)
      }
    end
  end
end

