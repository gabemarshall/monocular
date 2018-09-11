require 'faraday'
require 'json'
require 'slop'
require 'awesome_print'

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

  def Api.notify_takeover(domain, msg, job_id)
    conn = Faraday.new $API_HOST
    
    resp = conn.post do |req|
      req.url MonocleRoutes::CREATE_ISSUE
      req.headers['X-Monocle-Key'] = $API_KEY
      req.body = 'jobid='+job_id.to_s+'&severity=critical&rule='+domain+'&name='+msg
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

  def Api.get_all_urls()
    conn = Faraday.new $API_HOST
    resp = conn.get do |req|
      req.url MonocleRoutes::ALL_URLS
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