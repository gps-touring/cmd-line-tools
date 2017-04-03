require 'nokogiri'
module XmlP
  class XsdTypes
    def self.parse(x, type)
      return
      case type
      when "xsd:decimal"
	x.to_f
      else
	$stderr.puts "Warning: not XsdTypes for #{type}"
	x
      end
    end
  end
  class Parser
    attr_reader :res,:root
    def initialize(xml_file, root_element_name, root_element_class, class_map)
      @res = {}
      @@class_map = class_map
      doc = File.open(xml_file) { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }

      if doc.root.name == root_element_name
	@res[doc.root.name] = root_element_class.new(doc.root)
	@root = @res[root_element_name]
      else
	$stderr.puts "Expected root element " + root_element_name + ", found " + doc.root.name.name
      end

    end
    def self.parse_complex_type(x, attrs, eles)
      #$stderr.puts "XmlP.Parser.parse_complex_type"
      res = Hash.new {|h, k| h[k] = [] }
      x.attributes.each {|k, v|
	#$stderr.puts v.name
	#$stderr.puts v.value
	begin
	  res[v.name] << @@class_map[attrs[v.name][:type]].new(v.value)
	rescue
	  $stderr.puts v.name + " not found in class_map"
	end
	#if @@class_map[attrs[v.name][:type]]
	  #res[v.name] << @@class_map[attrs[v.name][:type]].new(v.value)
	#else
	  #$stderr.puts v.name + " not found in class_map"
	#end

      }
      #pp x.children.map {|x| x.name  }
      x.children.each {|x|
	begin
	  res[x.name] << @@class_map[eles[x.name][:type]].new(x)
	rescue
	  $stderr.puts x.name + " not found in class_map"
	end

	#if @@class_map[eles[x.name][:type]]
	  #res[x.name] << @@class_map[eles[x.name][:type]].new(x)
	#else
	  #$stderr.puts x.name + " not found in class_map"
	#end
      }
      pp res.keys
      res
    end
    def self.parse_simple_type(x, restriction)
      $stderr.puts "XmlP.Parser.parse_simple_type"

      pp x
      pp restriction
      XmlP::XsdTypes.parse(x, restriction["type"])

      #case restriction['type']
      #when "xsd:decimal"
	#x.to_f
      #else
	#$stderr.puts "No code to handle simpletype #{restriction['type']}"
	#x
      #end
    end
    class ComplexType
      def initialize(xml_node, eles, attrs)
        @xml_node = xml_node
	@eles = eles
	@attrs = attrs
	@res = nil # to become obsolete

	# @at, @el hahses hold references to other XmlP::Parser objects
	# Each reference is populated when it is accessed.
	# Until then, it does not appear in the hash at all.
	# @at is a hash from attriute name string to XmlP::Parser object
	# @el is a hash from element name string to XmlP::Parser object

	@at = {}
	# There can be more than one element of each name (subject to maxOccurs restriction)
	@el = Hash.new {|h, k| h[k] = [] }
	$stderr.puts "ComplexType @el init"
      end
      def get_element(n)
	if !@el.include?(n)
	  $stderr.puts "get_element (\"#{n}\")"
	  pp @xml_node

	end
	raise "Assertion failure" unless @el.include?(n)
	@el[n]
      end
    end
    class SimpleType
      def initialize(xml_node)
        @xml_node = xml_node
	@res = nil
      end
    end
  end
end
