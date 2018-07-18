require 'rufus-scheduler'
require_relative('api_helper')

scheduler = Rufus::Scheduler.new(:frequency => 1)

scheduler.every '4h' do
  domains = Api.get_all_domains()
  hosts = []
  File.delete('takeovers.txt') rescue puts "File does not exist"
  sleep 5
  open('takeovers.txt', 'a') do |f|
  	domains.each do |domain|
  		f.puts "#{domain['dns_name']},#{domain['dns_record']}"
  	end
  end
  
  
  scan = Enumeration.new
  scan.takeovers("test.com")
end