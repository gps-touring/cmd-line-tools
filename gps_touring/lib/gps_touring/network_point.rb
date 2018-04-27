require 'pp'
module GpsTouring
  class NetworkPoint < Geom::Point
    attr_reader :links, :definitions, :lat, :lon
    def initialize(geoloc)
      @lat, @lon = geoloc
      super(@lon, @lat)
      # The same latitude and longitude may be defined in several places (e.g. more than once in GPX files)
      # There may also be definitions that do not come from GPX waypoints.
      # All such definitions are kept here:
      @definitions = []

      # links are NetworkPoints reachable by a single hop 
      # i.e. adjacent <rtept> or <trkpt> elements in the <rte> or <trkseg> gps data:
      @links = []
    end
    def sanity_check
      # Check invariants
      [
	# All GPX waypoints for this point have identical lat and lon:
	@definitions.map{|w| w.geoloc}.uniq.size == 1,

	# All points linked to have different lat/long:
	@links.size == @links.map {|p| p.geoloc}.uniq.size

      ].each_with_index {|success, index|
	raise "Invariant[#{index}] failed (index starts at 0)" unless success
      }
    end
    def key
      definitions.first.geoloc
    end
    def sequence_point?
      @definitions.find { |d| d.sequence_point? }
    end
    def calling_point?
      @definitions.find { |d| d.calling_point? }
    end
    def intersection_point?
      @definitions.find { |d| d.intersection_point? }
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
    def add_definition(definition)
      @definitions << definition
      self
    end
    def add_bidirectional_link(p)
      self.add_link_to(p)
      p.add_link_to(self)
    end
    def remove_bidirectional_link(p)
      self.remove_link_to(p)
      p.remove_link_to(self)
    end
    def add_link_to(p)
      return if p === self
      # p will already be in @links if there is a sequence of waypoints like this:
      # p, q, p
      # and here we would have self == q
      # In this case q must be treated as the end of an edge - i.e. it will have just one link.
      @links << p unless @links.include?(p)
    end
    def remove_link_to(p)
      unless @links.delete(p)
	raise "Attempt to delete line non-existent link from #{self.to_s} to #{p.to_s}"
      end
    end
    def link_count
      @links.size
    end
    def to_s
      "name: #{name}, lat: #{lat_s}, lon: #{lon_s}, ele: #{ele}"
    end
    def lat_s
      lat.to_s
    end
    def lon_s
      lon.to_s
    end
    def ele
      definitions.map {|d| d.ele}.compact.first
    end
    def ele=(x)
      @ele = x
    end
    def name
      return @name if defined? @name
      names = definitions.map {|d| d.name}.compact.sort.uniq
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
    def to_gpx_wpt(xml)
      xml.wpt(lat: lat_s, lon: lon_s) {
	xml.name(name) if name
	xml.ele(ele) if ele
      }
    end
  end
end

