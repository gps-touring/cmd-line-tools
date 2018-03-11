require_relative "gpx/builder"

module GpsTouring
  module NetworkPointsArray
    # Can be included in any class which defines 
    # - a points method to return an array of GpsModule::NetworkPoint objects
    def to_gpx
      GpsTouring::GPX::Builder.new {|xml| to_gpx_rte(xml) }.to_xml
    end
    def elevation_edge(metres = 2)
      ElevationEdge.new(points, metres)
    end
    def to_gpx_rte(xml)
      xml.rte {|xml|
	to_gpx_name(xml)
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
	["start ele", points.first.ele, "m"],
	["end ele", points.last.ele, "m"],
	["ascent", metres_up, "m"],
	["descent", metres_down, "m"],
	["height gained", ele_gain, "m"],
	["points", points.size, ""]
      ]
      xml.desc data.map {|x| "#{x[0]}: #{x[1,2].join}"}.join("; ")
    end
    def to_gpx_name(xml)
      xml.name gpx_name
    end
    def to_gradient_csv(original_points = points)
      prev = nil
      cumm_dists = cumm_distances_using_original_points(original_points)
      points.zip(cumm_dists).map{|z|
	# There's one fewer elements in the result than in the points
	# and this first nil element will be removed by compacting the array
	res = nil 
	if prev
	  res = [
	    prev[0].ele, 
	    z[0].ele, 
	    prev[1].round(1), 
	    z[1].round(1), 
	    z[0].ele - prev[0].ele, 
	    (z[1] - prev[1]).round(0), 
	    ((z[0].ele - prev[0].ele)/(z[1] - prev[1])*100).round(1)
	  ].join(',')
	end
	prev = z
	res
      }.compact.join("\n")
    end
    def cumm_distances_using_original_points(orig_pts)
      # Precondition: points is a subset of orig_pts in the following sense:
      # Points is contained in orig_pts (as a set), AND
      # they are in the same order.
      #
      # Returns an array of cummulative distances between points
      # where the distances are calculated based on orig_pts. 
      cumm = []
      total = 0.0
      prev = nil
      index = 0
      orig_pts.each {|p|
	if prev
	  total += prev.distance_m(p)
	end
	prev = p
	if p === points[index]
	  cumm << total
	  index += 1
	end
      }
      raise "Bad array size" unless cumm.size == points.size
      cumm
    end

    def name
      "#{points.first.name} - #{points.last.name}"
    end
    def fname
      # Name to be used when constructing filenames about this point
      "#{points.first.fname}-#{points.last.fname}"
    end
    def metres_distance
      total = 0.0
      prev = points.first
      points.each {|p| 
	total += prev.distance_m(p)
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
