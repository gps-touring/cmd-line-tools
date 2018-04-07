require 'ostruct'

module GpsTouring
  class PointDefinition < OpenStruct
    class Type
      # Partof a sequence (e.g. from a GPX trkseg, or rte)
      SEQUENCE_POINT = 1
      CALLING_POINT = 2
    end
    attr_accessor :type
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
    def sequence_point?
      type == Type::SEQUENCE_POINT
    end
    def calling_point?
      type == Type::CALLING_POINT
    end
    def geoloc
      [lat, lon]
    end
  end
end
