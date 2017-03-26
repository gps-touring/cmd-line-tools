
XSD := gpx1_1.xsd
GPX := test.gpx
PARSER_GENERATOR := xsd2ruby-parser.rb
PARSER := gpx-parser.rb
PARSER_UTILS := parser-utils.rb
PARSER_OUT := gpx-parser-out.txt

$(PARSER_OUT) : $(PARSER) $(GPX) $(PARSER_UTILS)
	ruby $< $(GPX) > $@

$(PARSER) : $(PARSER_GENERATOR) $(XSD)
	ruby $< $(XSD) > $@
