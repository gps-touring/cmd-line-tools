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
$type = {}
class String
def capfirst
  self[0].upcase + self[1..-1]
end
end
class Super
  def initialize(x)
    @node = x
    @attr = x.attributes	# Hash of attributes, indexed by attr name.
    @docs = x.xpath("xsd:annotation").map {|x| Annotation.new(x)}
    $stderr.puts "DOCS: #{annotations}"
  end
  def name
    @attr["name"] ?  @attr["name"].value : ""
  end
  def type
    @attr["type"] ? @attr["type"].value : ""
  end
  def ruby_class_name
    $stderr.puts "name: #{name}"
    $stderr.puts "type: #{type}"
    name.capfirst
  end
  def ruby_class_ref
    $stderr.puts "name: #{name}"
    $stderr.puts "type: #{type}"
    type.capfirst
  end
  def annotations
    @docs.map{|x| x.docs}.join("\n")
  end
end
class Attribute < Super
  def initialize(x)
    super
    $stderr.puts "Attribute.initialize #{name} #{type}"
  end
end
class Element < Super
  def initialize(x)
    super
    $stderr.puts "Element.initialize #{name} #{type}"
  end
end
class SimpleType < Super
  def initialize(x)
    super
    @restrictions = x.xpath("xsd:restriction").map{|x| Restriction.new(x)}
    $type[name] = self
    $stderr.puts "SimpleType.initialize #{name}"
  end
end
class ComplexType < Super
  def initialize(x)
    super
    @attributes = x.xpath("xsd:attribute").map{|x| Attribute.new(x) }
    @elements = x.xpath("xsd:sequence/xsd:element").map{|x| Element.new(x) }
    $type[name] = self
    $stderr.puts "ComplexType.initialize #{name}, #{@attributes.size} attributes, #{@elements.size} elements"
  end
  def to_ruby_class
    return <<END
    class #{ruby_class_name}
    #XmlP::Parser::@@class_map["#{name}"] = #{ruby_class_name}
      @@attrs = {#{@attributes.map {|a| "\"#{a.name}\" => \"#{a.type}\""}.join(", ")}}
      @@eles = {#{@elements.map {|a| "\"#{a.name}\" => \"#{a.type}\""}.join(", ")}}
      def self.parse(x)
        $stderr.puts "#{ruby_class_name}.parse"
        XmlP::Parser.parse(x, @@attrs, @@eles)
      end
    end
END
  end
  def class_map_defn
    return <<END
      @@class_map["#{name}"] = XmlP::Types::#{ruby_class_name}
END
  end
end
class Annotation < Super
  attr_reader :docs
  def initialize(x)
    #super
    @docs = x.xpath("xsd:documentation").text
    $stderr.puts "Annotation.initialize #{@docs}"
  end
end
class Restriction < Super
  def initialize(x)
    #super
    @base = x.attributes["base"]
    $stderr.puts "Restriction.initialize #{@base}"
  end
end

class XsdParser
  def initialize(xsd)
    doc = File.open(xsd) { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }
    @root_elements = doc.root.xpath("xsd:element").map { |x| Element.new(x) }
    raise "Expected exactly on root element in XSD" unless @root_elements.size == 1
    @root_element = @root_elements.first
    @complex_types = doc.root.xpath("xsd:complexType").map { |x| ComplexType.new(x) }
    @simple_types = doc.root.xpath("xsd:simpleType").map { |x| SimpleType.new(x) }
    @annotations = doc.root.xpath("xsd:annotation").map { |x| Annotation.new(x) }

    #pp(@complex_types.map {|x| x.name }, $stderr)
    #pp(@simple_types.map {|x| x.name }, $stderr)
    #pp(@root_elements.map {|x| x.name }, $stderr)
    #pp(@annotations.map {|x| x.docs }, $stderr)
  end

  def to_ruby
    return <<END
require 'nokogiri'
require 'pp'
module XmlP
  class Types
#{complex_classes}
  end
#{parser_class}
res = XmlP::Parser.new(ARGV[0])
end
END
  end
  private
  def complex_classes
    @complex_types.map {|x| x.to_ruby_class }.join("\n")
  end
  def parser_class
    return <<END
    class Parser
      @@class_map = {}
    #{"\n" + @complex_types.map {|x| x.class_map_defn }.join()}
      def initialize(xml_file)
        doc = File.open(xml_file) { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }
	#pp doc.root
	root_element_name = "#{@root_element.name}"
	root_element_class_name = "#{@root_element.ruby_class_ref}"
	$stderr.puts "expected root element name: " + root_element_name
	$stderr.puts "actual root element nme: " + doc.root.name

	if doc.root.name == root_element_name
	  XmlP::Types::#{@root_element.ruby_class_ref}.parse(doc.root)
	else
	  $stderr.puts "Expected root element " + root_element_name + ", found " + doc.root.name.name
	end

	#$stderr.puts "doc.root.name: " + doc.root.name
	root = doc.xpath("/#{@root_elements.first.name}")
	#pp root
        #puts "Parser"
	#puts "#{@root_elements.first.name}"
	#puts "#{@root_elements.first.type}"
      end
      def self.parse(x, attrs, eles)
        $stderr.puts "XmlP.Parser.parse"
        #pp x.attributes
        pp x.children.map {|x| x.name  }
	x.children.each {|x|
	  
	  if @@class_map[eles[x.name]]
	    @@class_map[eles[x.name]].parse(x)
	  else
	    $stderr.puts x.name + " not found in class_map"
	  end
	}
      end
    end
END
  end
end
#xsd_p = XsdParser.new(File.open("gpx1_1.xsd"))
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

#puts $type.keys
