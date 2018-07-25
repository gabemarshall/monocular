require_relative('./portscan')
require_relative('./brute')
require_relative('./banner')
require_relative('./http')
require_relative('./passive')
require_relative('./resolver')
require_relative("../tools/aquatone/lib/aquatone")
require 'resolv'
require 'diffy'
require 'paint'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'awesome_print'
require 'pry'

module Ports

  def self.top
    return "80,443,8080,8443,8888,8000,9443,10443,9200,5601,1099,3306,3128,5432,5672,6379,5984,27017,27018"
  end
  def self.top1000
    return "7,9,13,21-23,25-26,37,53,79-81,88,106,110-111,113,119,135,139,143-144,179,199,389,427,443-445,465,513-515,543-544,548,554,587,631,646,873,990,993,995,1025-1029,1110,1433,1720,1723,1755,1900,2000-2001,2049,2121,2717,3000,3128,3306,3389,3986,4899,5000,5009,5051,5060,5101,5190,5357,5432,5631,5601,5666,5800,5900,6000-6001,6379,6646,7001,7070,8000,8008-8009,8080-8081,8443,8888,9002,9100,9200,9300,9999-10000,32768,49152-49157"
  end
end

def err(input)
  puts Paint[input, :red]
end

def warn(input)
  puts Paint[input, :yellow]
end

class Enumeration
  def enumerate_active
    domains = Domain.all

    domains.each do |domain|
      Brute.run(domain.dns_name)
    end
  end

  def is_valid_ip(ip)
    return ip =~ Resolv::IPv4::Regex
  end

  def is_valid_subnet(subnet)
    return /(^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\/([1-2][0-9]|3[0-2])$)/.match(subnet)
  end

  def has_spaces?(target)
    return /(\s*)/
  end

  def enumerate_ip_list(ips, args=[])
    if args.length > 0
      puts "Scanning with #{args}"
      services = Portscan.run_list(ips, args)
      return services
    else
      puts "Scanning with top ports"
      services = Portscan.run_list(ips, Ports.top)
      return services
    end
  end

  def enumerate_ip(ip, args)
    if is_valid_ip(ip)
      puts "Valid ip address detected, #{ip} will be used for the scan"
    elsif is_valid_subnet(ip)
      puts "Valid subnet range detected, #{ip} will be used for the scan"
    elsif has_spaces?(ip)
      puts "Target has spaces and is either multiple ips or multiple domains"
      puts "#{ip} will be used for the target"
    else
      puts "Probable domain, lets check to see if it exists"
      domain_found = Domain.where(:dns_name => ip).first
      puts "Masscan prep => Already exists, using #{ip} for the scan"
    end
    begin
      is_domain = /\./ =~ args
      if args.length > 0 && is_domain.nil?
        services = Portscan.run(ip, args)
        #services = Masscan.save(masscan_runner)
        return services
      else
        services = Portscan.run(ip, Ports.top)

        return services
      end
    rescue => exception
      puts exception
      puts exception.backtrace
    end
  end

  def enumerate_banners(services)
    begin
      status_msg = "########### Enumerating Banners ############"

      puts status_msg
      temp_services = []
      wq = WorkQueue.new 25
      services.each do |service|
        wq.enqueue_b do
          banner_grab = Banner.new.grab(service[:ip], service[:port].to_i)
          temp_service = {:ip => service[:ip], :port => service[:port], :banner => banner_grab[:banner], service_type: banner_grab[:type]}
          puts temp_service.inspect
          temp_services.push(temp_service)
        end
      end
      wq.join
      return temp_services
    rescue => exception
      warn("Exception from bannergrab thrown for #{service}\n")
      err(exception)
      puts ""
    end
  end

  def http_is_valid?(content)
    if /SSL_connect/ =~ content || /failed to connect/ =~ content || /Timed out after using the allocated/ =~ content
      return false
    else
      return true
    end
  end

  def enumerate_domain(domain, recursive=false)
    unless recursive
      # When doing a recursive scan, we only do bruteforce
      aquatone_results = Passive.aquatone_discover(domain)
      
    end
    
    discovered_records = []
    discovered_records.concat(aquatone_results)
    
    # discovered_records = []
    # if crt_results
    #   new_domains = DNSResolver.new.res_async(crt_results)
    #   discovered_records.concat(new_domains)
    # end

    # if discovered_records.nil?
    #   discovered_records = []
    # end

    if recursive
      # use a small wordlist when doing recursive enumeration
      brute_discoveries = Brute.run(domain, 'monocle-tiny')
    else
      brute_discoveries = Brute.run(domain, 'monocle')
    end


    unless brute_discoveries.nil?
      discovered_records.concat(brute_discoveries)
    end
    
    # Remove any records that didn't resolve properly

    discovered_records = discovered_records.delete_if {|entry| !Resolv::IPv4::Regex.match?(entry[:record])}
    #discovered_records.uniq! {|hash| hash.values_at(:dns_name)}
    return discovered_records
  end

  def takeovers(domains)
  
    options = {
      :fallback_nameservers => %w(8.8.8.8 8.8.4.4),
      :file => 'takeovers.txt',
      :domain => 'all.com',
      :output => 'takeovers-log.txt',
      :threads => 25
    }


    takeover = Aquatone::Commands::Takeover.run(options)
    
    if takeover.length == 0
      puts "No vulnerable domains"
    else
      takeover.each do |vuln|
        msg = "Potential #{vuln[1]['service']} takeover on #{vuln[0]} (#{vuln[1]['resource']['value']})"
        domain = vuln[0]
        Api.notify_takeover(domain, msg)
      end
    end

  end

  def enumerate_http(services, domains = [])

    puts "########### Enumerating HTTP ############"
    services_enum_http = []
    non_http = []

    if domains.length > 0
      services.each do |service|
        value = domains.find { |d| d[:record] == service[:ip]} || nil
        services_enum_http.push({ip: service[:ip], hostname: value[:domain], port: service[:port], service_type: 'http', banner: service[:banner]})
      end
      # domains.each do |domain|

      #   value = services.find { |h| h[:ip] == domain[:record] } || nil

      #   unless value.nil?
      #     if value[:port]
      #       puts "Adding check with domain of #{domain[:domain]}"
      #       services.push({ip: domain[:record], hostname: domain[:domain], port: value[:port], service_type: 'http', banner: 'Unknown'})
      #     end
      #   end
      # end      
    else
      services_enum_http = services
    end
    

    services.uniq! {|hash| hash.values_at(:hostname, :ip, :port)}
    
    Typhoeus::Config.user_agent = "User-Agent: Mozilla/5.0 (Linux; U; Android 2.2; en-us; Droid Build/MonocleApp) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"

    hydra = Typhoeus::Hydra.new(max_concurrency: 15)
    #monocleConfig = {followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5, proxy: 'http://127.0.0.1:8080'}
    monocleConfig = {followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5}

    # save a copy of the nmap results for use on line...
    $resps = []
    $nmap_services = services
    
    services_enum_http.each do |service|
    

      begin
        if service[:banner]
          if service[:service_type].include?('http')
            if !service[:hostname].nil?
              uri = service[:hostname]
              puts "Scheduling HTTP enumeration for #{uri} "
            else
              uri = service[:ip]
              puts "Scheduling HTTP enumeration for #{uri} "
            end
            output = {}

            if service[:port].to_s == "443" || service[:port].to_s == "8443"
              puts "Port is #{service[:port]}"
              puts "Trying https://#{uri}:#{service[:port]}/"
             request = Typhoeus::Request.new("https://#{uri}:#{service[:port]}/", monocleConfig)
                request.on_complete do |response|
                  headers = response.response_headers rescue ""
                  headers = headers.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
                  banner = response.body.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip

                  $resps.push({ip: service[:ip], port: service[:port], hostname: service[:hostname], banner: banner, status_code: response.code, uri: response.effective_url, description: headers, service_type: 'https'})
                end              

            else
              puts "Da Port is #{service[:port]}"
              puts "Trying http://#{uri}:#{service[:port]}/"

              request = Typhoeus::Request.new("http://#{uri}:#{service[:port]}/", monocleConfig)
              request.on_complete do |response|
                headers = response.response_headers rescue ""
                headers = headers.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
                banner = response.body.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip

                $resps.push({ip: service[:ip], port: service[:port], hostname: service[:hostname], banner: banner, status_code: response.code, uri: response.effective_url, description: headers, service_type: 'http'})
              end

            end


            hydra.queue(request)

          end
        end
      rescue => exception
        warn("Exception thrown during http enum for #{service}\n")
        err(exception)
        puts ""
      end
    end
    hydra.run

    
    nmap_values = $nmap_services.delete_if {|service| service[:service_type].include?('http') }
    $resps = $resps+nmap_values
    
    $resps = $resps.sort_by{|a|a['description'].length rescue 0}.uniq{|h| h.values_at(:ip, :port, :hostname)}
    #$resps.uniq! {|hash| hash.values_at(:banner)}

    return $resps
  end



  def update_http(services, proxy=nil)

    puts "########### Updating HTTP Services ############"
    services_enum_http = []
    non_http = []

    http_services = []

    Typhoeus::Config.user_agent = "User-Agent: Mozilla/5.0 (Linux; U; Android 2.2; en-us; Droid Build/MonocleApp) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"

    hydra = Typhoeus::Hydra.new(max_concurrency: 5)

    if proxy.nil?
      monocleConfig = {followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5}
    else
      monocleConfig = {followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5, proxy: 'http://127.0.0.1:8080'}
    end
    responses = []
    services.each do |service|
      if service["uri"] && service["hostname"]
        if service["uri"].include?(service["hostname"])
          url = service["uri"]
        else
          tmp = service["uri"].split('/')
          url = tmp[0]+"//"+service["hostname"]+"/"
        end
      else
        url = service["uri"]
      end

      puts url

      request = Typhoeus::Request.new(url, monocleConfig)

      request.on_complete do |response|
        if response.code == 0
          puts "[!] Timeout for #{response.effective_url}"
        end
        headers = response.response_headers rescue ""
        headers = headers.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        banner = response.body.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip

        responses.push({ip: service[:ip], port: service[:port], hostname: service[:hostname], banner: banner, status_code: response.code, uri: response.effective_url, description: headers})
      end
      hydra.queue(request)
    end
    hydra.run

    return responses
  end

end

