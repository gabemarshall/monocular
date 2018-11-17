require_relative('enum')
require_relative('utils')
require_relative('api_helper')
require_relative('jobs/domain_sucker')

module JobHandler
  def JobHandler.take(job)
    puts "Taking available job"
    job_id = job['id']
    job_sched = job['schedule']
    target = job['target']
    is_expired = job['is_expired']
    task_type = job['task_type_id']
    args = job['arguments']
    
    tasks = job['add_tasks'] ||= [0]

    return if is_expired || job_sched != 'now'

    msg = Api.take_job(job_id)
    return if msg == "ERROR"

########## SUBDOMAIN ENUMERATION #############
    scan = Enumeration.new()
    job_results = {}

    if task_type == 1
      DomainJob.perform_async(job)
    elsif task_type == 2
      ########## PORT SCAN #############
      puts "Job Type => Port Scan"
      target_is_json = JSON.parse(target) rescue nil

      if target_is_json
        discovery_array_hash = target_is_json.map! { |entry| {domain:entry["domain"], record:entry["record"]} }

        job_results[:domains] = discovery_array_hash
        discovered_ips = []

        discovery_array_hash.each do |disc|
          discovered_ips.push(disc[:record])
        end

        # If port scan enrichment is enabled, begin nmap scan
        scan_results = []

        if discovered_ips.length > 0
          unique_ips = discovered_ips.sort.uniq
          puts "Discovered #{unique_ips.length} ips that need to be scanned, proceeding with portscan"

          enum_ip_results = scan.enumerate_ip_list(unique_ips, args)
          scan_results.concat(enum_ip_results)
        end

        if scan_results.length > 0
          if tasks.include?("3")
            puts "Grabbing banners for open ports"
            services = scan.enumerate_banners(scan_results)

            puts "Enumerating any HTTP services"
            services_final = scan.enumerate_http(services, discovery_array_hash)

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
      else
        masscan_result_array = scan.enumerate_ip(target, args)

        if masscan_result_array.nil?
          masscan_result_array = []
        end

        puts "Port scan completed, #{masscan_result_array.length} ports were discovered\n\n#{masscan_result_array.to_s}"
        if masscan_result_array.length > 0
          if tasks.include?("3")
            puts "Grabbing banners for open ports"
            services = scan.enumerate_banners(masscan_result_array)
            puts "Enumerating any HTTP services"

            services_final = scan.enumerate_http(services)
            job_results[:services] = services_final
            finalize(job_results, job_id)
          else
            job_results[:services] = masscan_result_array
            finalize(masscan_result_array, job_id)
          end
        end
      end
    elsif task_type == 5
      puts "Job Type => Update Services"
      services = get_services(target)
      results = scan.update_http(services)
      job_results[:services] = results
      finalize(job_results, job_id)
    elsif task_type == 6
      puts "Job Type => Domain Takeover"
      scan = Enumeration.new

      domains = Api.get_all_domains().map! {|dom|dom["name"].downcase }.sort.uniq
      targ = domains.first

      options = {
        :fallback_nameservers => %w(8.8.8.8 8.8.4.4),
        :file => 'takeovers.txt',
        :output => 'takeovers-log.txt',
        :threads => 25,
        :domain => targ
      }

      takeover = Aquatone::Commands::Takeover.run(options)

      if takeover.length == 0
        puts "No vulnerable domains"
      else
        takeover.each do |vuln|
          msg = "Potential #{vuln[1]['service']} takeover on #{vuln[0]} (#{vuln[1]['resource']['value']})"
          domain = vuln[0]
          Api.notify_takeover(domain, msg, job_id)
        end
      end
      update_job(job_id, "done")
    end
  end
end
