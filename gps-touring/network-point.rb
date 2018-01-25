module GpsTouring
class NetworkPoint
  attr_reader :links, :edges
  def initialize
    @wpts = []
    @links = []
    @edges = []
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
    e.from === self || raise("Bug - expected all edges are from this point")
    @edges << e
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

