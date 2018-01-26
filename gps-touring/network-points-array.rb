require_relative "gpx-builder"

module GpsTouring
  module NetworkPointsArray
    # Can be included in any class which defines a points method to return an array of GpsModule::NetworkPoint objects
    def to_gpx
      GpsTouring::GPX::Builder.new {|xml|
	xml.rte {|xml|
	  points.each {|p| p.to_rtept(xml)}
	}
      }.to_xml
    end
  end
end
