require 'faraday'
require 'json'
require 'slop'
require_relative('../lib/enum')
require_relative('../lib/api_helper')
require_relative('../lib/chores')

opts = Slop.parse do |o|
  o.string '-h', '--host', 'Monocle API Host'
  o.string '-k', '--key', 'API Key'
end
$API_KEY = opts[:key]
$API_HOST = opts[:host]

def check_jobs
  begin
    conn = Faraday.new $API_HOST
    resp = conn.get do |req|
      req.url '/api/jobs/pending'
      req.headers['X-Monocle-Key'] = $API_KEY
    end
    data = JSON.parse(resp.body)
    return data.first
  rescue => exception
    puts "Server appears to be offline"
  end
end

def get_services(query)
  Api.services_from_search($API_HOST, $API_KEY, query)
end

def get_all_domains()
  Api.get_all_domains($API_HOST, $API_KEY)
end


def take_job(id)
  conn = Faraday.new $API_HOST
  resp = conn.post do |req|
    req.url '/api/jobs/accept'
    req.headers['X-Monocle-Key'] = $API_KEY
    req.body = 'id=' + id.to_s
  end
  return resp.body
end

def finalize(data, job_id)
  data[:job_id] = job_id

  conn = Faraday.new $API_HOST
  resp = conn.post do |req|
    req.url '/api/jobs/finalize'
    req.headers['Content-Type'] = 'application/json'
    req.headers['X-Monocle-Key'] = $API_KEY
    req.body = data.to_json
  end

  puts "Bye!"
end

loop do
  job = check_jobs

  this_job = job['job_schedule'] rescue nil
  unless this_job.nil?
    job_id = job['id']
    job_sched = job['job_schedule']
    job_target = job['job_target']
    job_expired = job['job_expired']
    task_type = job['task_type_id']
    args = job['arguments']
    tasks = job['add_tasks'] ||= [0]

    if job_sched == "now"
      msg = take_job(job_id)
      unless msg == "ERROR"

        # SUBDOMAIN ENUMERATION
        scan = Enumeration.new()
        job_results = {}

        if task_type == 1
          puts "subdomain enum"
          puts tasks

          # Run domain enumeration
          discovery_array_hash = scan.enumerate_domain(job_target, false)
          recursive_hash = discovery_array_hash

          job_results[:domains] = recursive_hash.uniq {|hash| hash.values_at(:domain)}
          discovered_ips = []
          discovered_domains = []

          discovery_array_hash.each do |disc|
            discovered_ips.push(disc[:record])
            discovered_domains.push(disc[:domain])
          end

          # If port scan enrichment is enabled, begin nmap scan
          scan_results = []
          if tasks.include?("2")
            puts "Portscan requested"

            if discovered_ips.length > 0
              unique_ips = discovered_ips.sort.uniq
              puts "Discovered #{unique_ips.length} ips that need to be scanned, proceeding with portscan"

              enum_ip_results = scan.enumerate_ip_list(unique_ips, args)
              scan_results.concat(enum_ip_results)
            end
          end

          if scan_results.length > 0
            if tasks.include?("3")
              discovery_array_hash = []

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
          end

          # PORT SCAN

        elsif task_type == 2
          puts "Job Type => Port Scan"
          masscan_result_array = scan.enumerate_ip(job_target, args)

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
        elsif task_type == 5
          puts "Job Type => Update Services"
          services = get_services(job_target)
          results = scan.update_http(services)
          job_results[:services] = results
          finalize(job_results, job_id)
        elsif task_type == 6
          puts "Job Type => Domain Takeover"
          domain_file_path = get_domains()
          results = scan.domain_takeover(domain_file_path)
          job_results[:domains] = results
          finalize(job_results, job_id)
        end
      end
    end
  end

  sleep 5
end
