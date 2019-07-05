require 'nmap/program'

Nmap::Program.scan do |nmap|
  nmap.syn_scan = false 
  nmap.service_scan = true
  nmap.os_fingerprint = false
  nmap.xml = 'scan.xml'
  nmap.verbose = true

  nmap.ports = [20,21,22,23,25,80,110,443,512,522,8080,1080]
  nmap.targets = '192.168.0.*'
end
