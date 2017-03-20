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
class Super
  def initialize(x)
    @node = x
    @attr = x.attributes	# Hash of attributes, indexed by attr name.
    #@children = []
    @docs = x.xpath("xsd:annotation").map {|x| Annotation.new(x)}
    puts "DOCS: #{annotations}"
    #x.attribute_nodes.each {|c|
      #puts "#{c.name}: #{c.value}"
    #}
    #if false 
      #x.children.each {|c|
	#puts c.name
	#if $element_class_map[c.name]
	  #@children << $element_class_map[c.name].new(c)
	#else
	  #$stderr.puts "WARNING(in #{x.name}): element \"#{c.name}\" could not be parsed"
	#end
      #}
     #end
  end
  def name
    @attr["name"] ?  @attr["name"].value : ""
  end
  def type
    @attr["type"] ? @attr["type"].value : ""
  end
  def annotations
    @docs.map{|x| x.docs}.join("\n")
  end
end
class Attribute < Super
  def initialize(x)
    super
    puts "Attribute.initialize #{name} #{type}"
  end
end
class Element < Super
  def initialize(x)
    super
    puts "Element.initialize #{name} #{type}"
  end
end
class SimpleType < Super
  def initialize(x)
    super
    @restrictions = x.xpath("xsd:restriction").map{|x| Restriction.new(x)}
    $type[name] = self
    puts "SimpleType.initialize #{name}"
  end
end
class ComplexType < Super
  def initialize(x)
    super
    @attributes = x.xpath("xsd:attribute").map{|x| Attribute.new(x) }
    @elements = x.xpath("xsd:sequence/xsd:element").map{|x| Element.new(x) }
    $type[name] = self
    puts "ComplexType.initialize #{name}, #{@attributes.size} attributes, #{@elements.size} elements"
  end
end
class Annotation < Super
  attr_reader :docs
  def initialize(x)
    #super
    @docs = x.xpath("xsd:documentation").text
    puts "Annotation.initialize #{@docs}"
  end
end
class Restriction < Super
  def initialize(x)
    #super
    @base = x.attributes["base"]
    puts "Restriction.initialize #{@base}"
  end
end

class XsdParser
  def initialize(xsd_io)
    doc = File.open("gpx1_1.xsd") { |f| Nokogiri::XML(f) { |cfg| cfg.noblanks } }
    @root_elements = doc.root.xpath("xsd:element").map { |x| Element.new(x) }
    @complex_types = doc.root.xpath("xsd:complexType").map { |x| ComplexType.new(x) }
    @simple_types = doc.root.xpath("xsd:simpleType").map { |x| SimpleType.new(x) }
    @annotations = doc.root.xpath("xsd:annotation").map { |x| Annotation.new(x) }

    pp @complex_types.map {|x| x.name }
    pp @simple_types.map {|x| x.name }
    pp @root_elements.map {|x| x.name }
    pp @annotations.map {|x| x.docs }
  end
end
xsd_p = XsdParser.new(File.open("gpx1_1.xsd"))


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
