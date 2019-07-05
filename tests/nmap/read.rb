require 'nmap/xml'

Nmap::XML.new('scan.xml') do |xml|
  xml.each_host do |host|
    puts "[#{host.ip}]"

    host.scripts.each do |name,output|
      output.each_line { |line| puts "  #{line}" }
    end

    host.each_port do |port|
      puts "  [#{port.number}/#{port.protocol}]"

      port.scripts.each do |name,output|
        puts "    [#{name}]"

        output.each_line { |line| puts "      #{line}" }
      end
    end
  end
end
