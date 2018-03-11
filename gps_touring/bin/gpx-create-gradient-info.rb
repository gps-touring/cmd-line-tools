require 'optparse'
require 'fileutils'
require 'pp'
require 'gps_touring'

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
  original = edge.original_edge
  if options.metres.nil?
    filename = "#{edge.fname}-original-gradients.csv"
    Dir.chdir(options.outdir) do
      File.open(filename, "w") {|f| f.write(original.to_gradient_csv)}
    end
  else
    smoothed = original.elevation_edge(options.metres)
    filename = "#{edge.fname}-smoothed-gradients-#{options.metres}.csv"
    Dir.chdir(options.outdir) do
      File.open(filename, "w") {|f|
	# The original.points will be used for calculating distances,
	# because the smoothed ones will be less accurate:
	f.write(smoothed.to_gradient_csv(original.points))
      }
    end
  end
}
