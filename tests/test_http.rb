require 'typhoeus'
require 'http'
require 'benchmark'
require 'chronic_duration'

# timeout = {:write => 3, :connect => 3, :read => 5}
# headers = {:referer => "https://frg12.monocleapp.com", :user_agent => "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Droid Build/FRG22D) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1"}
# ctx = OpenSSL::SSL::SSLContext.new
# ctx.verify_mode = OpenSSL::SSL::VERIFY_NONE

# puts "Trying HTTP"
# response = HTTP.timeout(timeout).headers(headers).get("http://155.199.210.22/", ssl_context: ctx)
# puts response.body

# puts "Trying Faraday"
# conn = Faraday.new "http://155.199.64.64/", :ssl => {:verify => false}
# resp = conn.get "http://155.199.64.64/"

# puts resp.body
services = []
# services.push({host: 'https://155.199.40.152:443/'})
# services.push({host: 'https://155.199.64.202:443/'})
# services.push({host: 'http://155.199.210.22/'})

# services.push({host: 'http://192.168.0.101:8000/'})

requests = []
m = Benchmark.measure {
333.times do |service|
  services.push('http://127.0.0.1:8000')
  services.push('http://127.0.0.1:8888')
end


# hydra = Typhoeus::Hydra.new
# requests = requests.map { |req|
#   request = Typhoeus::Request.new(req, followlocation: true, ssl_verifypeer: false, timeout: 5, ssl_verifyhost: 0)
#   hydra.queue(request)
#   request
# }
# hydra.run

# responses = requests.map { |request|
#   puts request.response.body
# }

# hydra = Typhoeus::Hydra.new
# requests = requests.map { |req|
#   request = Typhoeus::Request.new(req, followlocation: true, ssl_verifypeer: false, timeout: 5, ssl_verifyhost: 0)
#   hydra.queue(request)
#   request
# }
# hydra.run

# responses = requests.map { |request|
#   puts request.response.body
# }

hydra = Typhoeus::Hydra.new(max_concurrency: 60)
services.each do |service|
  request = Typhoeus::Request.new("#{service}", followlocation: true, ssl_verifypeer: false, timeout: 5, ssl_verifyhost: 0)
  request.on_complete do |response|
    #puts response.code
  end
  hydra.queue(request)
end
hydra.run
};
puts ChronicDuration.output(m.real)

# hydra ||= Typhoeus::Hydra.hydra

#   request = Typhoeus::Request.new(
#     url: service[:host],
#     headers: {'content-type' => 'application/json'},
#     method: :get
#   )

#   hydra.queue request
#   request

# hydra.run

# responses = requests.map { |request|
#   request.response.body
# }
