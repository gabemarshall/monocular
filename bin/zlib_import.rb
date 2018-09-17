require 'zlib'
puts ARGV[0]
infile = open(ARGV[0])
gz = Zlib::GzipReader.new(infile)
gz.each_line do |line|
    reg = Regexp.new '\.com$'
    puts reg.match? line
    puts line
    exit
end
