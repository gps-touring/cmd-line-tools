require_relative "gpx-builder"

module GpsTouring
  module NetworkPointsArray
    # Can be included in any class which defines a points method to return an array of GpsModule::NetworkPoint objects
    def to_gpx
      GpsTouring::GPX::Builder.new {|xml| to_gpx_rte(xml) }.to_xml
    end
    def to_gpx_rte(xml)
      xml.rte {|xml| to_gpx_rtepts(xml) }
    end
    def to_gpx_rtepts(xml)
      points.each {|p| p.to_gpx_rtept(xml) }
    end
    def to_gpx_trkseg(xml)
      xml.trkseg {|xml| to_gpx_trkpts(xml) }
    end
    def to_gpx_trkpts(xml)
      points.each {|p| p.to_gpx_trkpt(xml) }
    end
  end
end
