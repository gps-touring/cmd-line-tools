require 'rxsd'

#xsd_uri = "file:///home/user/schema.xsd"
#xml_uri = "file:///home/user/data.xml"
xsd_uri = "file:///Users/matt/Cycling/gps-touring/cmd-line-tools/gpx-parser/gpx1_1.xsd"
xml_uri = "file:///Users/matt/Cycling/gps-touring/cmd-line-tools/gpx-parser/test.gpx"

schema = RXSD::Parser.parse_xsd :uri => xsd_uri

puts "=======Classes======="
classes = schema.to :ruby_classes
puts classes.collect{ |cl| !cl.nil? ? (cl.to_s + " < " + cl.superclass.to_s) : ""}.sort.join("\n")

puts "=======Tags======="
puts schema.tags.collect { |n,cb| n + ": " + cb.to_s + ": " + (cb.nil? ? "ncb" : cb.klass_name.to_s + "-" + cb.klass.to_s) }.sort.join("\n")

puts "=======Objects======="
data = RXSD::Parser.parse_xml :uri => xml_uri
objs = data.to :ruby_objects, :schema => schema
objs.each {  |obj|
  puts "#{obj}"
}
