require 'csv'
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
	["start ele", points.first.ele || '?', "m"],
	["end ele", points.last.ele || '?', "m"],
	["ascent", metres_up.round(0), "m"],
	["descent", metres_down.round(0), "m"],
	["height gained", ele_gain.round(0), "m"],
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
      ::CSV.generate {|csv|
	points.zip(cumm_dists).each_cons(2).map{|z|
	  # a, b represent two adjacent points
	  #  a[0] and b[0] are NetowrkPoints
	  #  a[1] and b[1] are cumm. distances.
	  a,b = z	
	  dist = b[1] - a[1]

	  ele_diff =
	    begin
	      b[0].ele - a[0].ele
	    rescue
	      nil
	    end
	  grad =
	    begin
	      (ele_diff/dist*100).round(1)
	    rescue
	      nil
	    end
	  csv << [a[0].ele, b[0].ele, a[1].round(1), b[1].round(1), ele_diff, dist.round(0), grad]

	}
      }
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
      points.each_cons(2).map { |pair|
	pair[0].distance_m(pair[1])
      }.inject(0, :+)
    end
    def metres_up
      elevation_array.compact.find_all {|x| x > 0}.inject(0, :+)
    end
    def metres_down
      -elevation_array.compact.find_all {|x| x < 0}.inject(0, :+)
    end
    private
    def elevation_array
      # returns an array of size one less than size of points
      # each element is the difference between the next and the prev point.
      # If Either prev or next elevation is undefined, then corresponding element will be nil.
      points.each_cons(2).map {|pair_of_points|
	a, b = pair_of_points
	begin
	  b.ele - a.ele
	rescue
	  nil
	end
      }
    end
  end
end
