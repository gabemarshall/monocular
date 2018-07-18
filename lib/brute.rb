require 'work_queue'
require 'open3'


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
        brute_args = "-d #{domain} --wordlist wordlists/#{word}.txt --threads 50 -o output/#{domain}-brute.txt"
        brute_safe_args = brute_args.split(" ")
         
        Open3.popen2e('./tools/aquatone/exe/aquatone-discover', *brute_safe_args) do |stdin, stdout_stderr, wait_thread|
            Thread.new do
                stdout_stderr.each {|l| 
                puts l
             }
            end
          
          
            wait_thread.value
          end

        discoveries = []
        
        begin
            File.open('output/'+domain+'-brute.txt', 'r') do |results|

                results.each_line do |line|
                    temp = line.strip.split(",")
                    dns_discovery = temp[0].downcase
                    ip = temp[0].downcase
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
