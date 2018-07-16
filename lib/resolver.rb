require 'dnsruby'
require 'resolv'

class DNSResolver
    include Dnsruby
    def res_sync(domain)
        resolver = Resolver.new
        begin
            dns_response = resolver.query(domain) # Defaults to A record
            
            dns_response.answer.each do |record|
                
                if record.type == "A"
                    puts "Record Type => #{record.type}"
                    puts "Record Value => #{record.name}"
                    
                    puts record.name
                    puts record.type
                    return record.address
                end
            end
        rescue Exception => error
            puts "Error resolving"
        end
    end

    def res_async(domain_array)
        resolv = DNSResolver.new
            
        new_domains = []
        wq = WorkQueue.new 15

        begin
            domain_array.each do |domain|
                wq.enqueue_b do
                    puts "########### DEBUG #############"
                    puts "Trying to resolve #{domain}"
                    puts "######### END DEBUG ###########"
                    ip =  DNSResolver.new.res_sync(domain)

                    if ip.nil?
                        puts "Do nothing"
                    else
                        puts "Domain #{domain} resolved to #{ip}"
                        ip = ip.to_s                        
                        case ip
                        when ::Resolv::IPv4::Regex
                              puts "It's a valid IPv4 address."
                              temp = {:domain => domain, :record => ip.to_s}
                              new_domains.push(temp)
                        else
                            puts "Invalid Ip Address"
                        end
                    end
                end
            end
            wq.join                
        rescue => exception
            puts exception
            new_domains = nil
        end

        return new_domains
        
    end

end