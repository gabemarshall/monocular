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
  def Api.services_from_search(query)
    conn = Faraday.new $API_HOST
    resp = conn.get do |req|
      req.url "#{MonocleRoutes::SEARCH}?q=#{query}"
      req.headers['X-Monocle-Key'] = $API_KEY
    end
    
    return JSON.parse(resp.body)

  rescue => exception
    puts exception.backtrace
  end

  def Api.notify_takeover(domain, msg)
    conn = Faraday.new $API_HOST
    
    resp = conn.post do |req|
      req.url MonocleRoutes::CREATE_ISSUE
      req.headers['X-Monocle-Key'] = $API_KEY
      req.body = 'severity=critical&rule='+domain+'&name='+msg
    end

    return resp.body
  end

  def Api.get_all_domains()
    conn = Faraday.new $API_HOST
    resp = conn.get do |req|
      req.url MonocleRoutes::ALL_DOMAINS
      req.headers['X-Monocle-Key'] = $API_KEY
    end
    
    return JSON.parse(resp.body)

  rescue => exception
    puts exception.backtrace
  end

  def Api.get_domains_query(query)
    conn = Faraday.new $API_HOST
    resp = conn.get do |req|
      req.url "#{MonocleRoutes::SEARCH_DOMAINS}?q=#{query}"
      req.headers['X-Monocle-Key'] = $API_KEY
    end
    
    return JSON.parse(resp.body)

  rescue => exception
    puts exception.backtrace
  end
end

if opts[:debug]
  $API_HOST = opts[:host]
  $API_KEY = opts[:key]

  services = Api.services_from_search(opts[:query])
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
