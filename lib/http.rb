require 'sucker_punch'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'benchmark'
require 'socket'
require 'http'
require 'openssl'
require 'resolv'
require 'pry'

class HttpResponse
  def self.analyze(service)
    def determine_redirect(location)
      location = location.strip
      protocol = location.split(':')[0]
      host = location.split(':')[1].gsub('//', '').gsub('/', '')
      port = location.split(':')[2].gsub('//', '').gsub('/', '') rescue nil

      data = {proto: protocol, hostname: host, port: port}
      return data
    end

    puts service
  end
end

class JobCounter
  def initialize(count)
    @count = count
    @service_array = []
  end

  def get_count
    return @count
  end

  def add(item)
    @service_array.push(item)
  end

  def services
    return @service_array
  end

  def subone
    @count = @count - 1
    return @count
  end
end

class HttpGrabber

    def self.run(services=[], opts={})
        Typhoeus::Config.user_agent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.99 Safari/537.36"

        hydra = Typhoeus::Hydra.new(max_concurrency: 25)
        if opts[:proxy]
          monocleConfig = {headers: {"X-Host" => "nEkTMLFV8ZC0", "X-Forwarded-Host" => "nEkTMLFV8ZC1", "X-Forwarded-Server"=>"nEkTMLFV8ZC2", "X-Original-URL"=>"nEkTMLFV8ZC3"},followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5, proxy: opts[:proxy]}
        else
          monocleConfig = {headers: {"X-Host" => "nEkTMLFV8ZC0", "X-Forwarded-Host" => "nEkTMLFV8ZC1", "X-Forwarded-Server"=>"nEkTMLFV8ZC2", "X-Original-URL"=>"nEkTMLFV8ZC3"},followlocation: true, ssl_verifypeer: false, ssl_verifyhost: 0, connecttimeout: 5, timeout: 5}
        end
        $resps = []
        
        services.each do |service|

            begin
                hostname_exists = true
                if service.key? :hostname
                  hostname = service[:hostname]
                  uri = service[:hostname]
                else
                  hostname = service[:ip]
                  uri = service[:ip]
                  if Resolv::IPv4::Regex.match?(service[:ip])
                    hostname_exists = false
                    hostname = nil
                  end
                end

                output = {}

                if service[:port].to_s == "443" || service[:port].to_s == "8443" || opts[:ssl] || opts[:tls]
                    puts "Queuing https://#{uri}:#{service[:port]}/"
                    begin
                      if !hostname_exists
                        ssl_props = HttpGrabber.ssl_props(service[:ip], service[:port])
                        if ssl_props.has_key? 'cn'
                          uri = ssl_props[:cn]
                          hostname_exists = true
                        end
                      end                    
                    rescue => exception

                    end
                    
                    request = Typhoeus::Request.new("https://#{uri}:#{service[:port]}/", monocleConfig)
                    request.on_complete do |response|
                        headers = response.response_headers rescue ""
                        headers = headers.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
                        banner = response.body.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip
                        if !Resolv::IPv4::Regex.match?(service[:ip])
                            service[:ip] = response.primary_ip
                        end
                        unless banner.length == 0
                          $resps.push({ip: service[:ip], port: service[:port], hostname: hostname, banner: banner, status_code: response.code, uri: response.effective_url, description: headers, service_type: 'https'})
                        end
                    end

                else
                    puts "Queuing http://#{uri}:#{service[:port]}/"

                    request = Typhoeus::Request.new("http://#{uri}:#{service[:port]}/", monocleConfig)
                    request.on_complete do |response|
                        if response.code == 0
                          puts "Request to #{hostname} error'd out"
                        else
                          puts "Request to #{hostname} has completed successfully"
                        end
                        headers = response.response_headers rescue ""
                        headers = headers.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
                        banner = response.body.to_s.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?').strip
                        if !Resolv::IPv4::Regex.match?(service[:ip])
                            service[:ip] = response.primary_ip
                        end
                        unless banner.length == 0
                          if headers.length > 0
                            $resps.push({ip: service[:ip], port: service[:port], hostname: hostname, banner: banner, status_code: response.code, uri: response.effective_url, description: headers, service_type: 'http'})
                          else
                            $resps.push({ip: service[:ip], port: service[:port], hostname: hostname, banner: banner})
                          end
                        end
                    end

                end


                hydra.queue(request)



            rescue => exception

                puts ""
            end
        end
        hydra.run
        return $resps
    end

      def self.ssl_props(hostname, port)
        tcp_client = TCPSocket.new(hostname, port)
        ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
        ssl_client.connect
        cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
        ssl_client.sysclose
        tcp_client.close

        certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
        issuer = certprops.select { |name, data, type| name == "O" }.first[1]

        name = OpenSSL::X509::Name.parse cert.subject.to_s
        cn = name.to_a.find { |name, _, _| name == 'CN' }[1] rescue nil
        o = name.to_a.find { |name, _, _| name == 'O' }[1] rescue nil

        results = {
          :valid_on => cert.not_before,
          :valid_until => cert.not_after,
          :issuer => issuer,
          :valid => (ssl_client.verify_result == 0),
          :org => o,
          :cn => cn,
        }

        return results
      end

      def determine_redirect(location)
        location = location.strip
        protocol = location.split(':')[0]
        host = location.split(':')[1].gsub('//', '').gsub('/', '')
        port = location.split(':')[2].gsub('//', '').gsub('/', '') rescue nil

        data = {proto: protocol, hostname: host, port: port}
        return data

      end
end
