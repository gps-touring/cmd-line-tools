require 'ostruct'

module GpsTouring
  class PointDefinition < OpenStruct
    def initialize(hash)
      super
    end
    def self.from_gpx_waypoint(wpt)
      xml_text = lambda {|e| e && e.text}
      xml_text_to_f = lambda {|e| e && e.text.to_f}
      new(
	lat: wpt['lat'].to_f,
	lon: wpt['lon'].to_f,
	ele: xml_text_to_f.call(wpt.at_css('ele')),
	name: xml_text.call(wpt.at_css('name'))
      )
    end
    def geoloc
      [lat, lon]
    end
  end
end
