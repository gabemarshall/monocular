module Aquatone
  module Commands
    class Takeover < Aquatone::Command
      def execute!
        
        if !options[:domain] || !options[:file]
          output("Please specify a domain to assess and a path to a json file to load domains from\n")
          exit 1
        end

        @domain     = Aquatone::Domain.new(options[:domain])
        @assessment = Aquatone::Assessment.new(options[:domain])

        banner("Takeover")
        prepare_host_dictionary
        prepare_detectors
        setup_resolver
        check_hosts
        results = write_to_takeovers_file
        return results
      end

      private

      def prepare_host_dictionary      
        hosts = File.readlines(options[:file])
        @hosts = hosts.map {|line| line.split(',')[0]}
        output("Loaded #{bold(@hosts.count)} hosts from #{bold(options[:file])}")
      end

      def prepare_detectors
        @detectors = Aquatone::Detector.descendants
        output("Loaded #{bold(@detectors.count)} domain takeover detectors\n\n")
      end

      def setup_resolver
        if options[:nameservers]
          nameservers = options[:nameservers]
        else
          nameservers = []
        end

        if !nameservers.empty?
          output("Using nameservers:\n\n")
          nameservers.each do |ns|
            output(" - #{ns}\n")
          end
          output("\n")
        end
        @resolver = Aquatone::Resolver.new(
          :nameservers          => nameservers,
          :fallback_nameservers => options[:fallback_nameservers]
        )
      end

      def check_hosts
        pool                = thread_pool
        @task_count         = 1
        @takeovers          = {}
        @takeovers_detected = 0
        @start_time         = Time.now.to_i
        output("Checking hosts for domain takeover vulnerabilities...\n\n")
        @hosts.each do |host|
          resource = @resolver.resource(host)
          next unless valid_resource?(resource)
          pool.schedule do
            output_progress if asked_for_progress?
            @task_count += 1
            @detectors.each do |detector|
              next if skip_detector?(detector)
              detector_instance = detector.new(host, resource)
              if detector_instance.positive?
                resource_type  = resource.class.to_s.split("::").last
                resource_value = resource.is_a?(Resolv::DNS::Resource::IN::CNAME) ? resource.name.to_s : resource.address.to_s
                output(red("Potential domain takeover detected!\n"))
                output("#{bold('Host...........:')} #{host}\n")
                output("#{bold('Service........:')} #{detector.meta[:service]}\n")
                output("#{bold('Service website:')} #{detector.meta[:service_website]}\n")
                output("#{bold('Resource.......:')} #{resource_type} #{resource_value}\n")
                output("\n")
                @takeovers[host] = {
                  "service"         => detector.meta[:service],
                  "service_website" => detector.meta[:service_website],
                  "description"     => detector.meta[:description],
                  "resource"        => {
                    "type"  => resource_type,
                    "value" => resource_value
                  }
                }
                @takeovers_detected += 1
                break
              end
            end
          end
          jitter_sleep
        end
        pool.shutdown
        output("Finished checking hosts:\n\n")
        output(" - Vulnerable     : #{bold(red(@takeovers_detected))}\n")
        output(" - Not Vulnerable : #{bold(green(@hosts.count - @takeovers_detected))}\n\n")
      end

      def write_to_takeovers_file
        
        output("Wrote #{bold(@takeovers.keys.count)} potential subdomain takeovers to:\n\n")

        if options[:output]
          File.open(options[:output], 'w') { |file| file.write(@takeovers.to_json) }
          output(" - #{bold(options[:output])}\n\n")
        else
          puts "2"
          @assessment.write_file("takeovers.json", @takeovers.to_json)
          output(" - #{bold('file://' + File.join(@assessment.path, 'takeovers.json'))}\n\n")
        end

        return @takeovers
        
        
      end

      def output_progress
        output("Stats: #{seconds_to_time(Time.now.to_i - @start_time)} elapsed; " \
               "#{@task_count} out of #{@hosts.count} hosts checked (#{@takeovers_detected} takeovers detected); " \
               "#{(@task_count.to_f / @hosts.count.to_f * 100.00).round(1)}% done\n")
      end

      def valid_resource?(resource)
        [Resolv::DNS::Resource::IN::CNAME, Resolv::DNS::Resource::IN::A].include?(resource.class)
      end

      def skip_detector?(detector)
        if options[:only_detectors]
          if options[:only_detectors].include?(detector.sluggified_name)
            false
          else
            true
          end
        elsif options[:disable_detectors]
          if options[:disable_detectors].include?(detector.sluggified_name)
            true
          else
            false
          end
        else
          false
        end
      end
    end
  end
end
