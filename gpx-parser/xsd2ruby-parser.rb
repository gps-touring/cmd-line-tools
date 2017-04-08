require 'nokogiri'
require 'pp'

# Each XML file has a root element
# Each element has a type
# Each element may contain child elements
# Each element may contain attributes
# We map the element types onto ruby classes
# Each child element has a ruby method to access it.
# If a child element may have more than one occurrence, it is represented as an array.
# If a child element has at most one occurrence, it is a simple (non-array)
# There may be a max of one occurrence of each attribute, so use non-array valued methods.
 
# In XML,
# elements have a name (tag name), and a type.
# attributes have a name and a type.
# Complex types have elements and attributes.
# Simple types have restrictions (includes the underlying type)
# All of the above can have annotations
#
class String
def capfirst
  self[0].upcase + self[1..-1]
end
end
def genref
  caller_line = caller.first.split(":")[1]
  "# Code generated at #{__FILE__}:#{caller_line}  "
end
class Super
  def initialize(x)
    @node = x
    @attr = x.attributes	# Hash of attributes, indexed by attr name.
    @docs = x.xpath("xsd:annotation", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map {|x| Annotation.new(x)}
    #@docs = x.xpath("xsd:annotation").map {|x| Annotation.new(x)}
    #$stderr.puts "DOCS: #{annotations}"
  end
  def name
    @attr["name"] ?  @attr["name"].value : ""
  end
  def type
    @attr["type"] ? @attr["type"].value : ""
  end
  def ruby_class_name
    #$stderr.puts "name: #{name}"
    #$stderr.puts "type: #{type}"
    name.capfirst
  end
  def ruby_class_ref
    #$stderr.puts "name: #{name}"
    #$stderr.puts "type: #{type}"
    type.capfirst
  end
  def class_map_defn
    return "\"#{name}\" => XmlP::Types::#{ruby_class_name}"
  end
  def min_occurs
    #$stderr.puts "Super.min_occurs"
    begin
      @attr["minOccurs"].value.to_i
    rescue
      1
    end
  end 
  def max_occurs
    begin
      v = @attr["maxOccurs"].value
      v == "unbounded" ? "Float::INFINITY" : v.to_i
    rescue
      1
    end
  end 
  def annotations
    @docs.map{|x| x.docs}.join("\n")
  end
end
class Attribute < Super
  def initialize(x)
    super
    #$stderr.puts "Attribute.initialize #{name} #{type}"
  end
end
class Element < Super
  def initialize(x)
    super
    #$stderr.puts "Element.initialize #{name} #{type}"
  end
end
class SimpleType < Super
  def initialize(x)
    super
    restrictions = x.xpath("xsd:restriction", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map{|x| Restriction.new(x)}
    raise "Expected exactly one restriction for #{name}" unless restrictions.size == 1
    @restriction = restrictions.first
    #$stderr.puts "SimpleType.initialize #{name}"
  end
  def to_ruby_class
    return <<END
    #{genref}
    class #{ruby_class_name} < XmlP::Parser::SimpleType
      #attr_reader :res
      @@foo = #{@restriction.to_ruby_structure}
      def initialize(xml_node)
        #$stderr.puts "#{ruby_class_name}.initialize"
	super
        @res = XmlP::Parser.parse_simple_type(xml_node, #{@restriction.to_ruby_structure})
      end
    end
END
  end
end
class ComplexType < Super
  def initialize(x)
    super
    @attributes = x.xpath("xsd:attribute", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map{|x| Attribute.new(x) }
    @elements = x.xpath("xsd:sequence/xsd:element", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map{|x| Element.new(x) }
    #$type[name] = self
    #@attributes = x.xpath("xsd:attribute").map{|x| Attribute.new(x) }
    #@elements = x.xpath("xsd:sequence/xsd:element").map{|x| Element.new(x) }
    all_names = (@attributes + @elements).map {|x| x.name}
    if all_names.size != all_names.uniq.size
      raise "Some elements and attributes have the same name, breaking assumptions of this code generator: #{all_names.join(';')}"
    end
    $stderr.puts all_names.join(';')
    #$stderr.puts "ComplexType.initialize #{name}, #{@attributes.size} attributes, #{@elements.size} elements"
  end
  def to_ruby_class
    return <<END
    #{genref}
    class #{ruby_class_name} < XmlP::Parser::ComplexType
      @@attrs = {
        #{@attributes.map {|a| "\"#{a.name}\" => {type: \"#{a.type}\"}"}.join(",\n        ")}
      }
      @@eles = {
        #{@elements.map {|a| "\"#{a.name}\" => {type: \"#{a.type}\", minOccurs: #{a.min_occurs}, maxOccurs: #{a.max_occurs}}"}.join(",\n        ")}
      }
      # TODO - beware name class with res and an element or attribute
      attr_reader :res
      def initialize(xml_node)
        #$stderr.puts "#{ruby_class_name}.initialize"
	super(xml_node, @@eles, @@attrs)
      end
    end
END
  end
end
class Annotation < Super
  attr_reader :docs
  def initialize(x)
    #super
    @docs = x.xpath("xsd:documentation", 'xsd' => 'http://www.w3.org/2001/XMLSchema').text
    #@docs = x.xpath("xsd:documentation").text
    #$stderr.puts "Annotation.initialize #{@docs}"
  end
end
class Restriction < Super
  def initialize(x)
    #super
    @base = x.attributes["base"]
    #$stderr.puts "Restriction.initialize #{@base}"
  end
  def to_ruby_structure
    return "{\"type\" => \"#{@base}\"}"
  end
end

class XsdParser
  def initialize(xsd)
    doc = File.open(xsd) { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }
    $stderr.puts "doc.root: #{doc.root.name}"	# Expect doc.root.name to be "schema"
    @schema = doc.root
    #puts "doc.xpath schema:"
    #@schema = doc.xpath("xsd:schema", 'xsd' => 'http://www.w3.org/2001/XMLSchema')
    #pp @schema
    #puts "------"
    #raise "STOP"
    @root_elements = doc.root.xpath("xsd:element", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map { |x| Element.new(x) }
    raise "Expected exactly on root element in XSD" unless @root_elements.size == 1
    @root_element = @root_elements.first
    @complex_types = doc.root.xpath("xsd:complexType", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map { |x| ComplexType.new(x) }
    @simple_types = doc.root.xpath("xsd:simpleType", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map { |x| SimpleType.new(x) }
    @annotations = doc.root.xpath("xsd:annotation", 'xsd' => 'http://www.w3.org/2001/XMLSchema').map { |x| Annotation.new(x) }
  end

  def to_ruby
    return <<END
#{genref}
require 'nokogiri'
require 'pp'
require_relative './parser-utils.rb'
module XmlP
  class Types
#{complex_classes}
#{simple_classes}
  end
  #{genref}
  class #{@root_element.ruby_class_ref}
    class Parser
      def self.parse(filename)
	root_name = "#{@root_element.name}"
	root_type = XmlP::Types::#{@root_element.ruby_class_ref}
	type_map = #{class_map_defn}
	XmlP::Parser.new(filename, root_name, root_type, type_map)
      end
    end
  end
end
#{genref}
res = XmlP::#{@root_element.ruby_class_ref}::Parser.parse(ARGV[0])
res.root.get_element("#{@root_element.name}")
pp res
END
  end
  private
  def complex_classes
    @complex_types.map {|x| x.to_ruby_class }.join("\n")
  end
  def simple_classes
    @simple_types.map {|x| x.to_ruby_class }.join("\n")
  end
  def class_map_defn
    return "{
          #{(@complex_types + @simple_types).map{|x| x.class_map_defn}.join(",\n          ")}
        }"
  end
end
xsd_p = XsdParser.new(ARGV[0])
puts xsd_p.to_ruby

#pp doc.xpath("//xsd:complexType[@name]").map {|x| x.name}
#pp doc.xpath("//*[@name]").map {|x| "#{x.name} #{x['name']}"}
#pp doc.xpath("/*").map {|x| "#{x.name}"}
#pp doc.root.name
#pp doc.root.children.map {|x| "#{x.name}"  }
#doc.root.children.each {|x|
#
  #if $element_class_map[x.name]
    #$element_class_map[x.name].new(x)
  #else
    #$stderr.puts "WARNING: element #{x.name} could not be parsed"
  #end
#}

