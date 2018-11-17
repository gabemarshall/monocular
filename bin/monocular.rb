require 'faraday'
require 'json'
require 'slop'
require_relative('../lib/enum')
require_relative('../lib/api_helper')
require_relative('../lib/utils')
require_relative('../config/monocle_routes')
require_relative('../lib/job')
require_relative('../lib/jobs/domain_sucker')
require 'pry'

opts = Slop.parse do |o|
  o.string '-h', '--host', 'Monocle API Host'
  o.string '-k', '--key', 'API API Key'
  o.string '-q', '--query', 'API Search Query'
  o.string '-d', '--debug', 'Enable debug mode'
end

$API_KEY = opts[:key] ||= ENV['MONOCLE_KEY']
$API_HOST = opts[:host] ||= ENV['MONOCLE_HOST']

def check_jobs
  begin
    puts "Checking for Jobs"
    conn = Faraday.new $API_HOST

    resp = conn.get do |req|
      req.url MonocleRoutes::JOBS_PENDING
      req.headers['X-Monocle-Key'] = $API_KEY
    end
    data = JSON.parse(resp.body)
    return data.first
  rescue => exception
    puts "Server appears to be offline"
  end
end

def get_services(query)
  Api.services_from_search(query)
end

def get_all_domains()
  Api.get_all_domains()
end

def finalize(data, job_id)
  
  data[:job_id] = job_id

  conn = Faraday.new $API_HOST
  resp = conn.post do |req|
    req.url MonocleRoutes::FINALIZE_JOBS
    req.headers['Content-Type'] = 'application/json'
    req.headers['X-Monocle-Key'] = $API_KEY
    req.body = data.to_safe_json
  end

  puts "Bye!"
end

def update_job(job_id, status)
  conn = Faraday.new $API_HOST
  resp = conn.post do |req|
    req.url MonocleRoutes::UPDATE_JOB
    req.headers['X-Monocle-Key'] = $API_KEY
    req.body = 'id='+job_id.to_s+'&status='+status
  end
end

loop do
  sleep 5
  job = check_jobs()
  if job.nil?
    next
  else
    JobHandler.take(job)
  end
  

end
