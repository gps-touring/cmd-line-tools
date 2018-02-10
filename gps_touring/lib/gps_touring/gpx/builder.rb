require 'nokogiri'

module GpsTouring
  module GPX
    class Builder < Nokogiri::XML::Builder
      def initialize
	super { |xml|
	  xml.gpx(
	    xmlns: "http://www.topografix.com/GPX/1/1", 
	    version: "1.1",
	    creator: "GpsTouring"
	  ) {|xml|
	    yield(xml)
	  }
	}
      end
    end
    class Document < Nokogiri::XML::Document
    end
  end
end
