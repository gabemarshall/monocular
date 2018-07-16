require 'sucker_punch'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'
require 'benchmark'
require 'socket'
require 'http'
require 'openssl'

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
  include SuckerPunch::Job
  workers 4
  SuckerPunch.shutdown_timeout = 600000
  SuckerPunch.exception_handler = -> (ex, klass, args) { puts ex }

  def self.ssl_props(hostname, port)
    tcp_client = TCPSocket.new(hostname, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
    ssl_client.connect
    cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
    ssl_client.sysclose
    tcp_client.close

    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    issuer = certprops.select { |name, data, type| name == "O" }.first[1]

    #puts certprops.inspect

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

  def perform(host, port, proto, sucker)
    $depth_max = 4
    $depth = 0
    def self.request(host, port, proto)
      ctx = OpenSSL::SSL::SSLContext.new
      ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE
      timeout = {:write => 3, :connect => 3, :read => 5}
      headers = {:referer => "https://frg12.monocleapp.com", :user_agent => "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Droid Build/FRG22D) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"}

      ssl_props = nil
      if proto == "https"
        begin
          if port.class == String
            uri = host
          else
            uri = "https://#{host}:#{port.to_s}/"
          end

          response = HTTP.timeout(timeout).headers(headers).get(uri, ssl_context: ctx)
        rescue => exception
          warn("Exception thrown during self.request for #{port} on #{host}")

          err(exception)
        end
        if port.class == String
          original_host = host.strip.split(':')[1].gsub('//', '').gsub('/', '')
          original_port = host.strip.split(':')[2].gsub('//', '').gsub('/', '') rescue 443
          ssl_props = HttpGrabber.ssl_props(original_host, original_port)
        else
          ssl_props = HttpGrabber.ssl_props(host, port)
        end
      else
        begin
          if port.class == String
            uri = host
          else
            uri = "https://#{host}:#{port.to_s}/"
          end
          uri = "http://#{host}:#{port.to_s}/"

          response = HTTP.timeout(timeout).headers(headers).get(uri)
        rescue => exception
          puts exception.backtrace
          puts exception
          #return {banner: nil, status_code: nil, uri: nil}
        end
      end
      return {http: response, ssl: ssl_props}
    end
    http_obj = self.request(host, port, proto)

    while http_obj[:http].headers['Location'] && $depth < $depth_max
      loc = determine_redirect(http_obj[:http].headers['Location'])
      http_obj = self.request(http_obj[:http].headers['Location'], "location", loc[:proto])
      $depth += 1
    end

    header_cleaned = ""
    begin
      headers = nil_chain { http_obj[:http].headers }
      headers_cleaned = "HTTP/1.1 #{http_obj[:http].code}\n"
      headers.each do |key, array|
        headers_cleaned += "#{key} : #{array}\n"
      end
    rescue
      puts "Err"
    end
    c = sucker.subone
    sucker.add({banner: http_obj[:http].body.to_s, status_code: http_obj[:http].code, uri: http_obj[:http].uri.to_s, headers: headers_cleaned, ssl: http_obj[:ssl]})
    puts "#{c} jobs left"
    if c == 0
      puts "Job completed"
      puts sucker.services
    end
  end
end
