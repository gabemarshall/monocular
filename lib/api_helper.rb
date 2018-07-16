require 'faraday'
require 'json'
require 'slop'
require 'awesome_print'
require_relative('enum')

opts = Slop.parse do |o|
  o.string '-h', '--host', 'Monocle API Host'
  o.string '-k', '--key', 'API API Key'
  o.string '-q', '--query', 'API Search Query'
  o.string '-d', '--debug', 'Enable debug mode'
end



module Api
  def Api.services_from_search(host, key, query)

    conn = Faraday.new host
    resp = conn.get do |req|
      req.url '/api/search?q='+query
      req.headers['X-Monocle-Key'] = key
    end
    
    data = JSON.parse(resp.body)

    return data

  rescue => exception
    puts exception.backtrace
  end

end

if opts[:debug]
  services = Api.services_from_search(opts[:host],opts[:key], opts[:query])
  scan = Enumeration.new()

  scan.update_http(services)


  #services.each do |service|
    #ap service["type"]
    # if service["hostname"]
    #   puts
    # end
    #ap service["hostname"]
    # ap service["hostname"]
  #end
end
