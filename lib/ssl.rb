class Certificate
  def self.get(hostname, port)
    tcp_client = TCPSocket.new(hostname, port)
    ssl_client = OpenSSL::SSL::SSLSocket.new(tcp_client)
    ssl_client.connect
    cert = OpenSSL::X509::Certificate.new(ssl_client.peer_cert)
    ssl_client.sysclose
    tcp_client.close

    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    issuer = certprops.select { |name, data, type| name == "O" }.first[1]


    name = OpenSSL::X509::Name.parse cert.subject.to_s
    cn = name.to_a.find { |name, _, _| name == 'CN' }[1] rescue nil
    o = name.to_a.find { |name, _, _| name == 'O' }[1] rescue nil

    results = {
      :valid_on => cert.not_before,
      :valid_until => cert.not_after,
      :issuer => issuer,
      :valid => (ssl_client.verify_result == 0),
      :org => o,
      :cn => cn,
    }
    
    return results
  end
end