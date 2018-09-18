require 'pry'
module Aquatone
  module Collectors
    class Findsub < Aquatone::Collector
      self.meta = {
        :name         => "Findsubdomains.com",
        :author       => "Gabe Marshall (@gabemarshall)",
        :description  => "Uses findsubdomains.com to get additional hostnames"
      }

      def run
        response = get_request("https://findsubdomains.com/subdomains-map/#{url_escape(domain.name)}")
        
        body = response.body.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
        
        body.to_enum(:scan, /([a-zA-Z0-9\*_.-]+\.#{Regexp.escape(domain.name)})/).map do |record|
          add_host(record[0])
        end
      end
    end
  end
end