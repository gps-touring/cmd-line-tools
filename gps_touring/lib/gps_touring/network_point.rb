require 'pp'
module GpsTouring
  class NetworkPoint
    attr_reader :wpts, :links
    def initialize
      # wpts are all of the GPX waypoints (objects from Nokogiri) which have lat/lon that exactly match this NetworkPoint
      @wpts = []

      # links are NetworkPoints reachable by a single hop 
      # i.e. adjacent <rtept> or <trkpt> elements in the <rte> or <trkseg> gps data:
      @links = []

    end
    def self.wpt2key(wpt)
      # key for the @points hash:
      [wpt['lat'].to_f, wpt['lon'].to_f]
    end
    def sanity_check
      # Check invariants
      [
	# All GPX waypoints for this point have identical lat and lon:
	@wpts.map{|w| [w['lat'].to_f, w['lon'].to_f]}.uniq.size == 1,

	# All points linked to have different lat/long:
	@links.size == @links.map {|p| p.geoloc}.uniq.size

      ].each_with_index {|success, index|
	raise "Invariant[#{index}] failed (index starts at 0)" unless success
      }
    end
    def key
      self.class.wpt2key(wpts.first)
    end
    def distance_m(p)
      Geo::distance_in_metres(self, p)
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
    def add_bidirectional_link(p)
      self.add_link_to(p)
      p.add_link_to(self)
    end
    def add_link_to(p)
      return if p === self
      # p will already be in @links if there is a sequence of waypoints like this:
      # p, q, p
      # and here we would have self == q
      # In this case q must be treated as the end of an edge - i.e. it will have just one link.
      @links << p unless @links.include?(p)
    end
    def link_count
      @links.size
    end
    def to_s
      @wpts.first.to_s
    end
    def lat_s
      @lat_s ||= @wpts.first['lat']
    end
    def lon_s
      @lon_s ||= @wpts.first['lon']
    end
    def lat
      @lat ||= @wpts.first['lat'].to_f
    end
    def lon
      @lon ||= @wpts.first['lon'].to_f
    end
    def ele
      return @ele if defined? @ele
      @ele = @wpts.map {|wpt| wpt.at_css('ele')}.compact.map{|s| s.text.to_f}.first
    end
    def ele=(x)
      @ele = x
    end
    def name
      return @name if defined? @name
      names = @wpts.map {|w|
	n = w.at_css('name')
	n && n.text
      }.compact.sort.uniq
      @name = names.empty? ? nil : names.join('|')
    end
    def fname
      # Name to be used when constructing filenames about this point
      (name || "#{lat},#{lon}").gsub(/\s/, "_")
    end
    def geoloc
      [lat, lon]
    end
    def to_gpx_trkpt(xml)
      xml.trkpt(lat: lat_s, lon: lon_s) {
	xml.name(name) if name
	xml.ele(ele) if ele
      }
    end
    def to_gpx_rtept(xml)
      xml.rtept(lat: lat_s, lon: lon_s) {
	xml.name(name) if name
	xml.ele(ele) if ele
      }
    end
  end
end

