# This is work in progress - probably abondonned in favour of using an existing AVL Tree (balanced BTree) implementation.
#
require 'pp'

class Btree
  attr_reader :root
  def initialize
    @root = nil
  end
  def insert(k, v)
    # returns an array of the Nodes to reach the inserted item
    if @root
      @root.insert(k,v).unshift(@root)
    else
      [@root = Node.new(k, v)]
    end
  end
  def find(k)
    begin
      @root.find(k)
    rescue NoMethodError => e
      nil
    end
  end
  def delete(node, v)
    # node is defined by an array of nodes - as returned by insert or find
    if node.size == 1
      @root.values.delete(v)
      if @root.values.empty?
	right = @root.right
	@root = @root.left
	if @root
	  @root.insert_node(right)
	else
	  @root = right
	end
      end
    else
      node[-2].delete_child(node.last, v)
    end
  end
  def keys
    @root.keys
  end
  class NodeSeq < Array
    # NodeSeq is used as an address of a Node in the BTree.
    # It is the sequence of Nodes, starting at the root, and finishing with the Node in question.
  end
  class Node
    attr_reader :key, :values
    def initialize(k,v)
      @left, @right = nil, nil
      @key, @values = k, [v]
    end
    def insert(k, v)
      # Returns the sequence of Nodes
      case k <=> @key
      when 1
	if @right
	  @right.insert(k, v).unshift(@right)
	else
	  NodeSeq.new [@right = Node.new(k, v)]
	end
      when -1
	if @left
	  @left.insert(k, v).unshift(@left)
	else
	  NodeSeq.new [@left = Node.new(k, v)]
	end
      when 0
	@values << v
	NodeSeq.new
      end
    end
    def find(k)
      begin
	case k <=> @key
	when 1
	  @right.find(k).unshift(self)
	when -1
	  @left.find(k).unshift(self)
	when 0
	  NodeSeq.new [self]
	end
      rescue NoMethodError => e
	nil
      end
    end
    def delete_child(node)
      # Delete a specific child of this Node
      if node.key < key
	@left = node.left
	@left.insert_node(node.right)
      else
	@right = node.right
	@right.insert_node(node.left)
      end
    end
    private def insert_node(node)
      # This is really a subroutine of delete_child, and as such
      # some special preconditions assumed for this method:
      # Precondition: node.key does not alredy exist in the BTree
      #               (hence no test for 'when 0')
      case node.key <=> @key
      when 1
	if @right
	  @right.insert_node(node)
	else
	  @right = node
	end
      when -1
	if @left
	  @left.insert_node(node)
	else
	  @left = node
	end
      end
    end
    def keys
      [key] + (@left ? @left.keys : []) + (@right ? @right.keys : [])
    end

    def to_s
      "\"#{key.to_s}\":\t[#{values.map{|v| '"' + v.to_s + '"'}.join(',')}]"
    end
  end

end

class Test
  def initialize(key_func)
    @tree = Btree.new
    @key_func = key_func
    @tree_contents = []
  end
  def insert(obj)
    k, v = @key_func.call(obj), obj
    x = @tree.insert(k, v)
    @tree_contents << obj
    raise "Bad" unless x.last.key == k
    raise "Bad" unless x.first == @tree.root
    puts "---\ninsert(#{k.to_s}, #{v.to_s})\n#{x.map{|n| n.to_s}.join("\n")}"
    y = @tree.find(k)
    puts "---\nfind(#{k.to_s})\n#{y.map{|n| n.to_s}.join("\n")}"
    raise "Bad" unless x == y
  end
  def delete(obj)
    k, v = @key_func.call(obj), obj
    node = find(k)
    if node
      @tree.delete(node, v)
    end
    @tree_contents.delete(obj)
  end
  def delete_at_random
    if @tree_contents.size > 0
      delete(@tree_contents[Random.rand(@tree_contents.size)])
    end
  end
  def dump
    pp @tree
    puts "tree keys"
    pp @tree.keys
  end
end

class Klass
  attr_reader :k, :v
  def initialize(k, v)
    @k, @v = k, v
  end
  def to_s
    "#{v.to_s}"
  end
end
t = Test.new(lambda{|x| x.k})

(0 ...50).each {|i| 
  x = Klass.new(rand(100), i.to_s)
  t.insert(x)
}
t.dump
