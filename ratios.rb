# Assume we get two comma-separated lists of numbers
# e.g. 40,24 12,13,14,15,16,17,9,21,23
# Don't assume anything about the order.
# The rear is the one with more numbers
#
require 'pp'
Rings, Sprockets = ARGV.map {|list| list.split(',').sort}.sort{|a,b| a.size <=> b.size}
Wheel_diam = 27.0 #inches
CmPerInch = 2.54
Width = 8
Rpm = 80
class Gear
  attr_reader :ring, :sprocket
  def initialize(ring, sprocket)
    @ring, @sprocket = ring, sprocket
  end
  def ratio_inches
    Wheel_diam * ring.to_f / sprocket.to_f
  end
  def format_line
    ring_num = Rings.find_index(ring)
    vel = ratio_inches*Math::PI*Rpm*60*CmPerInch/100000
    #"#{ring} x #{sprocket} #{" "*Width*ring_num}#{ratio_inches.round(1).to_s.rjust(Width)}"
    "#{vel.round(1).to_s}\t\t#{sprocket.rjust((ring_num+1)*Width).ljust(Rings.size*Width)} #{" "*Width*ring_num}#{ratio_inches.round(1).to_s.rjust(Width)}"
  end
end
gears = Rings.map{|r| Sprockets.map{|s| Gear.new(r, s)}}.flatten

puts "km/h@#{Rpm}rpm\t" + Rings.map {|r| r.rjust(Width) }.join('') + "    #{Sprockets.size}-speed cassette"
gears.sort{|a, b| a.ratio_inches <=> b.ratio_inches}.reverse.each{|g| puts g.format_line}
