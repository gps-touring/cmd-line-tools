require 'optparse'
require 'fileutils'
require 'pp'
require 'gps_touring'

Opts = Struct.new(:outdir, :waypoints, :metres) do
  #Opts methods go here
end

options = Opts.new(nil, nil, nil)

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-oDIR", "--outdir DIR", "The name of the directory where files are to be created") do |dir|
    FileUtils.mkdir_p(dir)
    raise("#{dir} is not a directory") unless File.directory?(dir)
    options.outdir = dir
  end
  opts.on("-wFILE", "--waypoints FILE", "The name of the file containing the <wpt> elements for origin, callingpoints and destination") do |filename|
    options.waypoints = filename
  end
  opts.on("-mNUMBER", "--metres NUMBER", Float, "Elevation changes below this number of metres will be smoothed out") do |metres|
    options.metres = metres
  end
end.parse!


nwk = GpsTouring::Network.new(ARGV)
calling_network_points = nwk.set_calling_points(options.waypoints)
route = nwk.find_route(calling_network_points, GpsTouring::EdgeCost.by_distance_only)

Dir.chdir(options.outdir) do
  File.open("route.gpx", "w") {|f| f.write(GpsTouring::Path.new(route).to_gpx)}
end
