# Reverse the GPX.
# The output will have:
# All trk elements will be reverse
# within each trk element, the trksegs will be reversed
# Within each trkseg, the trkpts will be reversed
#
# All rte elements will be reversed
# Within each rte element, the rtepts will be reversed
#
require 'nokogiri'

#infile = ARGV[0]

#doc = Nokogiri::XML(File.open(infile), &:noblanks)
doc = Nokogiri::XML(ARGF.read, &:noblanks)

gpx = doc.at_css('gpx')

trks = doc.css('trk')
trks.each {|trk|
  trksegs = trk.css('trkseg')
  trksegs.each {|trkseg|
    trkpts = trkseg.css('trkpt')
    trkpts.unlink
    trkseg.add_child(trkpts.reverse)
  }
  trksegs.unlink
  trk.add_child(trksegs.reverse)
}
trks.unlink
gpx.add_child(trks.reverse)

rtes = doc.css('rte')
rtes.each {|rte|
  rtepts = rte.css('rtept')
  rtepts.unlink
  rte.add_child(rtepts.reverse)
}
rtes.unlink
gpx.add_child(rtes.reverse)


puts doc.to_xml(indent: 2)
