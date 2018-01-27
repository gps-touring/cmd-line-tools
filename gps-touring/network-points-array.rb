require_relative "gpx-builder"

module GpsTouring
  module NetworkPointsArray
    # Can be included in any class which defines a points method to return an array of GpsModule::NetworkPoint objects
    def to_gpx
      GpsTouring::GPX::Builder.new {|xml| to_gpx_rte(xml) }.to_xml
    end
    def to_gpx_rte(xml)
      xml.rte {|xml|
	to_gpx_desc(xml)
	to_gpx_rtepts(xml)
      }
    end
    def to_gpx_rtepts(xml)
      #$stderr.puts "to_gpx_rtepts"
      #$stderr.puts points.first
      points.each {|p|
	p.to_gpx_rtept(xml)
      }
    end
    def to_gpx_trkseg(xml)
      xml.trkseg {|xml|
	to_gpx_trkpts(xml)
      }
    end
    def to_gpx_trkpts(xml)
      points.each {|p|
	p.to_gpx_trkpt(xml)
      }
    end
    def to_gpx_desc(xml)
      xml.desc "ascent: #{metres_up}; descent: #{metres_down}"
    end

    def metres_up
      total = 0.0
      ps = points
      ele = ps.first.ele
      ps.each {|p|
	total += (p.ele - ele) if p.ele > ele
	ele = p.ele
      }
      total
    end
    def metres_down
      total = 0.0
      ps = points
      ele = ps.first.ele
      ps.each {|p|
	total += (ele - p.ele) if p.ele < ele
	ele = p.ele
      }
      total
    end
  end
end
