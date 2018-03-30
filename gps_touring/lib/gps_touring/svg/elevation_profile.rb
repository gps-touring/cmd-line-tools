require 'gps_touring'

module GpsTouring
  module SVG
    extend GpsTouring::Utils::Xml
    def SVG.elevation_profile(points, cumm_distances)
      ys = points.map {|p| p.ele || 0.0}
      scale = 100.0
      xs = cumm_distances.map {|x| x/scale }
      max_y = ys.max
      max_x = xs.max
      data = xs.zip(ys)
      
      xml(:svg, {
	xmlns: "http://www.w3.org/2000/svg",
	version: "1.1",
	width: "#{max_x}px",
	height: "#{max_y}px",
	viewBox: "0 0 #{max_x} #{max_y}"
      }) {
	# Horizontal lines every 100 metres:
	xml(:g, stroke: "black") {
	  (0 .. max_y.to_i/100).map {|i|
	    xml(:line, x1: 0, y1: max_y - i*100, x2: max_x, y2: max_y - i*100)
	  }.join("\n")
	} +
	# Vertical linkes every 10km:
	xml(:g, stroke: "black") {
	  (0 .. max_x.to_i/100).map {|i|
	    xml(:line, x1: i*100, y1: 0, x2: i*100, y2: max_y) +
	      xml(:text, x: i*100, y: max_y/2) { (10*i).to_s + "km" }
	  }.join("\n")
	} +
	data.each_cons(2).map {|d|
	  xml(:g,
	      stroke: gradient_rgb(scale*(d[0][0] - d[1][0]), d[0][1] - d[1][1])
	     ) {
	    xml(:line, {
	      x1: d[0][0], y1: max_y - d[0][1],
	      x2: d[1][0], y2: max_y - d[1][1]
	    })
	  }
	}.join("\n")
      }
    end
  end
end
