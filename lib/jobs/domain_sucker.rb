require_relative('../enum')
require_relative('../utils')
require_relative('../api_helper')
require 'sucker_punch'

class DomainJob
  include SuckerPunch::Job

  def perform(job)
    #Log.new(event).track
    puts "Taking available job"
    job_id = job['id']
    job_sched = job['schedule']
    target = job['target']
    is_expired = job['is_expired']
    task_type = job['task_type_id']
    args = job['arguments']
    tasks = job['add_tasks'] ||= [0]
    scan = Enumeration.new()
    job_results = {}

    puts "Starting subdomain enum job"
    puts tasks

    # Run domain enumeration
    discovery_array_hash = scan.enumerate_domain(target, false)
    # => [{:domain=>"confluence.eversec.rocks", :record=>"54.231.49.90"}]

    job_results[:domains] = discovery_array_hash
    discovered_ips = []

    discovery_array_hash.each do |disc|
      discovered_ips.push(disc[:record])
    end

    scan_results = []
    if tasks.include?("2")
      puts "Portscan requested"

      if discovered_ips.length > 0
        unique_ips = discovered_ips.sort.uniq
        puts "Discovered #{unique_ips.length} ips that need to be scanned, proceeding with portscan"

        enum_ip_results = scan.enumerate_ip_list(unique_ips, args)
        scan_results.concat(enum_ip_results)

        scan_results.each do |scan|
          matching_domain_record = discovery_array_hash.detect{|host| host[:record] == scan[:ip]}
          if matching_domain_record
            scan[:hostname] = matching_domain_record[:domain]
          end
        end

      end
    end

    if scan_results.length > 0
      if tasks.include?("3")
        #services = scan.enumerate_banners(scan_results)
        puts "Enumerating any HTTP services"
        # [{:ip=>"192.168.0.100", :port=>80, :banner=>"HTTP/1.1 400 Bad Request", :service_type=>"http"}]
        #services_final = scan.enumerate_http(services, discovery_array_hash)
        services_final = HttpGrabber.run(scan_results)
        puts "Finishing scan, banner enumeration was performed"
        job_results[:services] = services_final
        finalize(job_results, job_id)
      else
        job_results[:services] = scan_results
        puts "Finishing scan, no banner enumeration"
        finalize(job_results, job_id)
      end
    else
      finalize(job_results, job_id)
    end
  end
end