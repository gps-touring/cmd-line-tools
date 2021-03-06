require 'nokogiri'

# Reads GPX file passed into stdin.

# ARGUMENTS:
# 1. Child element name to be set (for each <wpt>)
# 2. Value to which to set it

# RESULT:
# Filtered GPX file will be written to stdout (containing only <wpt> elements)

# Example usage:
#     ruby <this_file.rb> sym House

($child, $value) = ARGV

$stderr.puts "Filtering for waypoints within the following bounding box"
$stderr.puts "Latitude: [#{$lat_min}, #{$lat_max}]"
$stderr.puts "Longitude: [#{$lon_min}, #{$lon_max}]"

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
  doc.css("wpt").map {|x| 
    total_in += 1
    total_out += 1
    child = x.at_css($child) 
    if child
      child.content = $value
    else
      x.add_child(xml($child) {$value })
    end
    x.to_xml + "\n"	# Use Nokogiri to convert the Node back to XML
  }.join
}
$stderr.puts "Waypoints input: #{total_in}, output: #{total_out}"
