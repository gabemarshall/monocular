require 'work_queue'
require 'open3'
require 'os'

class Brute
    def self.lookup_ip(ip)
        ip_address = IpAddress.where(:ip => ip).first
        if !ip_address
            puts "DEBUG => Creating new ip address"
            ip_address = IpAddress.new(:ip => ip)
        end

        return ip_address
    end

    def self.run(domain, word)
        wordlist = []

        start = Time.now
       
        # # Split into an array so that we can safely pass them to a system call
        #brute_args = "-i -m dns -u #{domain} -w wordlists/#{word}.txt -t 50 -o output/#{domain}-brute.txt"
        brute_args = "--domain=#{domain} --wordlist=wordlists/#{word}.txt -o output/#{domain}-brute.txt"
        
        brute_safe_args = brute_args.split(" ")
         
        # if OS.linux?
        #     brute_tool = './tools/gobuster-linux'
        # else
        #     brute_tool = './tools/gobuster'
        # end
        brute_tool = './tools/monocle-brute/monocle-brute'
        Open3.popen3(brute_tool, *brute_safe_args) do |stdin, stdout, stderr, wait_thr|
          while line = stdout.gets
            puts line
          end
        end        

        discoveries = []
        
        begin
            File.open('output/'+domain+'-brute.txt', 'r') do |results|

                results.each_line do |line|
                    dns_discovery = line.strip.split(" ")[1].downcase
                    ip = line.strip.split(" ")[2].downcase
                    ip = ip[1..-2] # strip '[' and ']'

                    # temp = line.strip.split(",")
                    # dns_discovery = temp[0].downcase
                    # ip = temp[0].downcase
                    discoveries.push({domain: dns_discovery, record: ip})
                end
                begin
                    File.delete('output/'+domain+'-brute.txt')
                rescue
                    puts "Handling error"
                end
            end
        rescue => exception
                        
        end
        

        return discoveries
    end
end
