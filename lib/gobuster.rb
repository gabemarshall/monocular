$VERBOSE = nil
#require_relative('ronin/lib/ronin')
# require 'ronin'
require 'work_queue'
require 'open3'


class Gobuster
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
        gobuster_args = "-d #{domain} --wordlist wordlists/#{word}.txt --threads 50 -o output/#{domain}-aquatone.txt"
        gobuster_safe_args = gobuster_args.split(" ")
         
        Open3.popen2e('./aquatone/exe/aquatone-discover', *gobuster_safe_args) do |stdin, stdout_stderr, wait_thread|
            Thread.new do
                stdout_stderr.each {|l| 
                puts l
             }
            end
          
          
            wait_thread.value
          end

        discoveries = []
        
        begin
            # TODO domains.any? {|d|d[:dns_name]=="vpnsdf.eversec.rocks"}  load all domains once
            File.open('output/'+domain+'-aquatone.txt', 'r') do |results|

                results.each_line do |line|
                    dns_discovery = line.strip.split(" ")[1].downcase
                    ip = line.strip.split(" ")[2].downcase
                    ip = ip[1..-2] # strip '[' and ']'
                    discoveries.push({domain: dns_discovery, record: ip})
                end
                begin
                    File.delete('output/'+domain+'-gobuster.txt')
                rescue
                    puts "Handling error"
                end
            end
        rescue => exception
                        
        end
        

        return discoveries
    end
end
