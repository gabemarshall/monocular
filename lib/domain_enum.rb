require_relative('./crt')
require_relative('./resolver')
require_relative('./gobuster')

module DomainEnum
  	def self.run(domain, recursive=false)

	    if recursive
	      crt_results = []
	    else
	      crt_results = CRT.search(domain)
	    end

	    discovered_records = []
	    if crt_results
	      new_domains = DNSResolver.new.res_async(crt_results)
	      discovered_records.concat(new_domains)
	    end

	    if discovered_records.nil?
	      discovered_records = []
	    end
	    if recursive
	      # use a small wordlist when doing recursive enumeration
	      gobuster_discoveries = Gobuster.run(domain, 'monocle-tiny')
	    else
	      gobuster_discoveries = Gobuster.run(domain, 'monocle')
	    end


	    unless gobuster_discoveries.nil?
	      discovered_records.concat(gobuster_discoveries)
	    end
	    return discovered_records
	end
end