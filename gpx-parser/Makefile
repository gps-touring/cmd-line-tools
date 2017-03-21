
XSD := gpx1_1.xsd
GPX := test.gpx
PARSER_GENERATOR := gpx-parser-generator.rb
PARSER := gpx-parser.rb
PARSER_OUT := gpx_parser_out.txt

$(PARSER_OUT) : $(PARSER) $(GPX)
	ruby $< $(GPX) > $@

$(PARSER) : $(PARSER_GENERATOR) $(XSD)
	ruby $< $(XSD) > $@
