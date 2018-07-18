require 'json'
require 'work_queue'
require 'nmap/xml'

require_relative('banner')
$new_services = 0
$services = []


require 'open3'

class Portscan
    def self.okay?(output, job)
        if output == "ERROR"
            return false
        else
            puts "Job healthcheck passed, continue"
            return true
        end
    end
    def self.run(target, args)

        rand_id = (0...10).map { ('a'..'z').to_a[rand(20)] }.join
        portscan_temp_file = "nmap-#{rand_id}.xml"
        portscan_args = "#{target} -p #{args} -Pn -n --open -T4 -vvv -oX output/#{portscan_temp_file} -oN output/#{rand_id}.nmap"
        
        # Split into an array so that we can safely pass them to a system call
        safe_arguments = portscan_args.split(" ")

        Open3.popen2e('nmap', *safe_arguments) do |stdin, stdout_stderr, wait_thread|
            Thread.new do
                stdout_stderr.each {|l|
                    puts l
                }
            end


            wait_thread.value
        end

        res = self.save('output/'+portscan_temp_file)

        return res
    end

    def self.run_list(ips, args)
        
        rand_id = (0...10).map { ('a'..'z').to_a[rand(20)] }.join
        portscan_temp_ips = "portscan-#{rand_id}.txt"
        portscan_temp_file = "portscan-#{rand_id}.xml"

        File.open('output/'+portscan_temp_ips, 'w') { |file| file.write(ips.join("\n")) }

        portscan_args = "-iL output/#{portscan_temp_ips} -p #{args} -Pn -n --open -T4 -oX output/#{portscan_temp_file}"

        safe_arguments = portscan_args.split(" ")

        Open3.popen2e('nmap', *safe_arguments) do |stdin, stdout_stderr, wait_thread|
            Thread.new do
                stdout_stderr.each {|l|
                    puts l
                }
            end


            wait_thread.value
        end
        
        res = self.save('output/'+portscan_temp_file)
        return res
    end

    def self.save(scan_file)
        final_results = []
        Nmap::XML.new(scan_file) do |xml|
            xml.each_host do |host|
              puts "[#{host.ip}]"
              host.each_port do |port|
                if port.state.to_s == "open"
                    final_results.push({ip: host.ip, port: port.number, type: port.service.to_s})
                end
              end
            end
        end
        puts "Deleting temporary files #{scan_file}}"
        File.delete(scan_file)
        return final_results
    end

end
