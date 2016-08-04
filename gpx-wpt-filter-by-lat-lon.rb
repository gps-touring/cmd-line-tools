require 'nokogiri'
require 'pp'

# Reads GPX file passed into stdin.

# ARGUMENTS:
# 1. Min/max latitudes, separated by a comma (no spaces)
# 2. Min/max longitudes, separated by a comma (no spaces)
# OPTIONALly:
# repeat 1, 2 again, to include another area in the output.

# RESULT:
# Filteres GPX file will be written to stdout (containing only <wpt> elements)

# Example usage:
#     ruby <this_file.rb> 48.5,48.8 -3.3,-4.1

class MinMax
  attr_reader :min, :max
  def initialize(minmax)	# e.g. "1.4,-0.7" NO SPACE around comma (will be sorted for you!)
    (@min, @max) = minmax.split(",").map{|x| x.to_f}.sort
  end
  def contains(x)
    x > min && x <= max
  end
  def to_s
    "[#{min},#{max}]"
  end
end
class Bounds
  attr_reader :lat_mm, :lon_mm
  def initialize(lat, lon)
    (@lat_mm, @lon_mm) = MinMax.new(lat), MinMax.new(lon)
  end
  def contains(lat, lon)
    lat_mm.contains(lat) && lon_mm.contains(lon)
  end
  def to_s
    "lat: #{lat_mm}, lon: #{lon_mm}"
  end
end

bounds = []
raise "Expected even number of arguments, they come in pairs: 'lat_bounds lon_bounds'\ne.g. '47.283,47.979  0.730,3.187 46.313,47.283  2.7,7.333'" unless ARGV.size.even?
while (ARGV.size != 0)
  bounds.push(Bounds.new(ARGV.shift, ARGV.shift))
end

$stderr.puts "Filtering for waypoints within the following bounding box"
$stderr.puts bounds

# Function for generating xml (used here for html).
def xml(ele, attr = {})
  "<#{ele}#{attr.keys.map{|k| " #{k}=\"#{attr[k]}\""}.join}>" + # Element opening tag with attributes.
    (block_given? ? yield : "") +       # Element contents.
    "</#{ele}>" # Element closing tag.
end

total_in = 0
total_out = 0
doc = Nokogiri::XML($stdin.read)
puts "<?xml version=\"1.0\"?>"
puts xml(:gpx, 
	 creator: "Matt Wallis",
	 version: "1.1",
	 xmlns: "http://www.topografix.com/GPX/1/1",
	 "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
	 "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd") {
  "\n" +
  doc.css("wpt").select {|x|
    total_in += 1
    lat = x.attributes["lat"].value.to_f
    lon = x.attributes["lon"].value.to_f
    bounds.map{|b|
      b.contains(lat, lon)
    }.reduce {|a, b| a || b}	# any b contains(lat lon), using logical OR
  }
  .map {|x| 
    total_out += 1
    sym = x.at_css("sym") 
    if sym
      #$stderr.puts "Yeah #{x.css("sym").size}" 
      sym.content = "Tent"
    else
      x.add_child(xml(:sym) {"Tent"})
    end
    x.to_xml + "\n"	# Use Nokogiri to convert the Node back to XML
  }.join
}
$stderr.puts "Waypoints input: #{total_in}, output: #{total_out}"
