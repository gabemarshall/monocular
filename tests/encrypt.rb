require "openssl"
require 'digest/sha2'
require 'base64'

wordlist = File.open('wordlists/tiny.txt').read
# We use the AES 256 bit cipher-block chaining symetric encryption
alg = "AES-256-CBC"

# We want a 256 bit key symetric key based on some passphrase
digest = Digest::SHA256.new
digest.update("asymetric key")
key = digest.digest
puts key.size
iv = OpenSSL::Cipher.new(alg).random_iv


#puts "Our key retrieved from base64"
#p key64.unpack('m')[0]
#raise 'Key Error' if(key.nil? or key.size != 32)
#
## Now we do the actual setup of the cipher
aes = OpenSSL::Cipher.new(alg)
aes.encrypt
aes.key = key
aes.iv = iv

#cipher = aes.update(wordlist)
#cipher << aes.update("This is some other string without linebreak.")
#cipher << aes.update("This follows immediately after period.")
#cipher << aes.update("Same with this final sentence")
#cipher << aes.final

#cipher64 = [cipher].pack('m')
cipher64 = File.open('test.txt').read

decode_cipher = OpenSSL::Cipher.new(alg)
decode_cipher.decrypt
decode_cipher.key = key
decode_cipher.iv = iv
begin
    plain = decode_cipher.update(cipher64.unpack('m')[0])
    plain << decode_cipher.final
    puts plain
rescue => exception
    puts exception
end
