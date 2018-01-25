require 'pp'
require_relative '../gps-touring/network'

# Takes a set of GPS tracks/routes and produces a logical graph.
# The logical graph is a GPX file with all points missed out unless they are end points or junctions.
# In other words, each point in the output has1, 3 or more than three points to which it is connected,
# but never 2.

nwk = GpsTouring::Network.new(ARGV)
#puts nwk.logical_graphs
puts nwk.logical_graphs_gpx
$stderr.puts "WARNING: There are #{nwk.logical_graphs.size} separate graphs - the routes/tracks are not fully connected" unless nwk.logical_graphs.size == 1
nwk.logical_edges.each {|e| puts e }
