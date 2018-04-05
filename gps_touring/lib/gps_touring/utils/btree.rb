require 'pp'

class Btree
  class Node
    def initialize(k,v)
      @left, @right = nil, nil
      @k, @vs = k, [v]
    end
    def insert(k, v)
      case k <=> @k
      when 1
	if @right
	  @right.insert(k, v)
	else
	  @right = Node.new(k, v)
	end
      when -1
	if @left
	  @left.insert(k, v)
	else
	  @left = Node.new(k, v)
	end
      when 0
	@vs << v
	self
      else
	raise "Unexpected return from <=>"
      end
    end

  end
  def initialize
    @root = nil
  end
  def insert(k, v)
    if @root
      @root.insert(k,v)
    else
      @root = Node.new(k, v)
    end
  end
end

t = Btree.new
t.insert(23, "horse23")
t.insert(20, "horse20")
t.insert(12, "horse12")
t.insert(22, "horse22")
pp t
