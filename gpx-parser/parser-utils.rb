module XmlP
  class Parser
    attr_reader :res
    def initialize(xml_file, root_element_name, root_element_class, class_map)
      @res = {}
      @@class_map = class_map
      doc = File.open(xml_file) { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }

      if doc.root.name == root_element_name
	res[doc.root.name] = root_element_class.parse(doc.root)
      else
	$stderr.puts "Expected root element " + root_element_name + ", found " + doc.root.name.name
      end

    end
    def self.parse_complex_type(x, attrs, eles)
      $stderr.puts "XmlP.Parser.parse_complex_type"
      res = Hash.new {|h, k| h[k] = [] }
      x.attributes.each {|k, v|
	$stderr.puts v.name
	$stderr.puts v.value
	if @@class_map[attrs[v.name]]
	  res[v.name] << @@class_map[attrs[v.name]].parse(v.value)
	else
	  $stderr.puts v.name + " not found in class_map"
	end

      }
      pp x.children.map {|x| x.name  }
      x.children.each {|x|

	if @@class_map[eles[x.name]]
	  res[x.name] << @@class_map[eles[x.name]].parse(x)
	else
	  $stderr.puts x.name + " not found in class_map"
	end
      }
      res
    end
    def self.parse_simple_type(x, restriction)
      $stderr.puts "XmlP.Parser.parse_simple_type"
      pp x
      pp restriction
    end
  end
end