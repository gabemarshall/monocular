require 'http'
require 'nokogiri'
require 'pry'
require_relative("../tools/aquatone/lib/aquatone")

class Passive

    def self.aquatone_discover(domain)
        
        passive_discoveries = []
        options = {
          :fallback_nameservers => %w(8.8.8.8 8.8.4.4),
          :domain => domain,
          :only_collectors => 'publicwww',
          #:disable_collectors => 'dictionary',
          :output => 'output/'+domain+'-passive.txt',
          :threads => 50
        }
        Aquatone::Commands::Discover.run(options)
        begin
            File.open('output/'+domain+'-passive.txt', 'r') do |results|
                
                results.each_line do |line|
                    temp = line.strip.split(",")
                    dns_discovery = temp[0].downcase
                    ip = temp[0].downcase
                    
                    passive_discoveries.push({domain: dns_discovery, record: ip})
                end
                begin
                    File.delete('output/'+domain+'-passive.txt')
                rescue
                    puts "Handling error"
                end

            end

            return passive_discoveries
        rescue => exception
            return nil
        end        
        # begin
        #     url = "https://crt.sh/?q=%25.#{domain}"

        #     response = HTTP.timeout(:global, :write => 25, :connect => 25, :read => 60)
        #                             .headers(:user_agent => "Mozilla/5.0 (Linux; U; Android 2.2; en-us; Droid Build/FRG22D) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.1").get(url)
            
        #     html_doc = Nokogiri::HTML(response.to_s)
        #     results = html_doc.css('body > table:nth-child(8) > tr > td > table > tr > td:nth-child(5)')
            
        #     result_array = []
        #     results.each do |result|
        #         result_array.push(result.text.downcase)
        #     end
        #     puts "\nRetrieved #{result_array.length} domains from crt.sh" 
        # rescue => exception
        #     result_array = nil
        # end

        # if result_array.nil?
        #     return result_array
        # else
        #     return result_array.sort.uniq
        # end
    end


end

