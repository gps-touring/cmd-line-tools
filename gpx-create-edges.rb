require 'optparse'
require 'fileutils'
require 'pp'
require_relative 'gps-touring/network'

Opts = Struct.new(:outdir, :metres) do
  #Opts methods go here
end

DefaultMetres = nil
options = Opts.new(nil, DefaultMetres)

OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"

  opts.on("-oDIR", "--outdir DIR", "The name of the directory where files are to be created") do |dir|
    FileUtils.mkdir_p(dir)
    raise("#{dir} is not a directory") unless File.directory?(dir)
    options.outdir = dir
  end
  opts.on("-mNUMBER", "--metres NUMBER", Float, "Elevation changes below this number of metres will be smoothed out") do |metres|
    options.metres = metres
  end
end.parse!

#pp options
#pp ARGV

nwk = GpsTouring::Network.new(ARGV)
nwk.logical_edges.each {|edge|
  if options.metres.nil?
    original = GpsTouring::OriginalEdge.new(edge)
    filename = "#{edge.name}-original.gpx"
    Dir.chdir(options.outdir) do
      File.open(filename, "w") {|f| f.write(original.to_gpx)}
    end
  else
    smoothed = GpsTouring::ElevationEdge.new(edge, options.metres)
    filename = "#{edge.name}-smoothed-#{options.metres}.gpx"
    Dir.chdir(options.outdir) do
      File.open(filename, "w") {|f| f.write(smoothed.to_gpx)}
    end
  end
}
