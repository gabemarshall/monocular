require 'socket'
require 'timeout'
require 'openssl'
require 'faraday'
require 'typhoeus'
require 'typhoeus/adapters/faraday'

class Banner
  def tcp_is_open(host, port)
    begin
      Timeout.timeout(1) do
        tcp_session(host, port)
      end

      return true
    rescue Timeout::Error
      return nil
    rescue SocketError, SystemCallError
      return false
    end
  end

  def tcp_connect(host, port)
    host = host.to_s
    port = port.to_i

    socket = TCPSocket.new(host, port)
    return socket
  end

  def tcp_session(host, port)
    Timeout.timeout(1) do
      socket = tcp_connect(host, port)
      socket.write('HEAD / HTTP/1.0\n\n')
      banner = socket.readline.strip
      socket.close
      return banner
    end
  rescue Timeout::Error
    return nil
  end

  def tcp_banner(host, port)
    banner = nil

    tcp_session(host, port) do |socket|
      socket.write('HEAD / HTTP/1.0\n\n')
      banner = socket.readline.strip
    end

    yield banner if block_given?
    if banner == nil
      banner = "Unknown"
    end
    return banner
  end

  def grab(host, port)
    banner = nil
    begin
      banner = tcp_session(host, port)
    rescue => exception
      banner = nil
    end

    if banner.nil?
      puts "check"
      response = Typhoeus.head("https://#{host}:#{port}/", ssl_verifypeer: false, timeout: 5, ssl_verifyhost: 0)
      banner = response.response_headers
    end

    return banner
  end

  def tcp(host, port)
    return tcp_banner(host, port)
  end
end
