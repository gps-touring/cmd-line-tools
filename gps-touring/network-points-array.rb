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
      ele_gain = metres_up - metres_down
      data = [
	["distance", (metres_distance/1000.0).round(2), "km"],
	["ascent", metres_up, "m"],
	["descent", metres_down, "m"],
	["height gained", ele_gain, "m"],
	["points", points.size, ""]
      ]
      xml.desc data.map {|x| "#{x[0]}: #{x[1,2].join}"}.join("; ")
    end

    def metres_distance
      total = 0.0
      prev = points.first
      points.each {|p| 
	total += p.distance_m(prev)
	prev = p
      }
      total
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
