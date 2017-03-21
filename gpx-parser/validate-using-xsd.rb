require 'nokogiri'
require 'pp'

PO_SCHEMA_FILE = "gpx1_1.xsd"
PO_XML_FILE = "test.gpx"
xsd = Nokogiri::XML::Schema(File.read(PO_SCHEMA_FILE))
doc = Nokogiri::XML(File.read(PO_XML_FILE))

xsd.validate(doc).each do |error|
  puts error.message
end
