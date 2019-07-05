require 'securerandom'
require 'slop'


opts = Slop.parse do |o|
  o.string '-h', '--host', 'Monocle API Host'
  o.string '-k', '--key', 'API API Key'
  o.string '-q', '--query', 'API Search Query'
  o.string '-d', '--debug', 'Enable debug mode'
  o.string '-t', '--token', 'Worker token generated from Monocle'
end

$API_KEY = opts[:key] ||= ENV['MONOCLE_KEY']
$API_HOST = opts[:host] ||= ENV['MONOCLE_HOST']
# SecureRandom.uuid
#
module MonocularSettings
  @unique_id = nil
  def MonocularSettings.id()
    @unique_id
  end
  def MonocularSettings.set_id(id)
    @unique_id = id
  end
  # this is just a variable
end

if opts[:token]
  MonocularSettings.set_id(opts[:token])
  File.open('.monocular_identity', 'w') { |file| file.write(opts[:token]) }
  puts "Monocular configuration has been successfully updated!"
  exit
end

if File.exist? '.monocular_identity'
	id_value = File.open('.monocular_identity').read
	MonocularSettings.set_id(id_value)
else
	puts 'Error, missing worker token. Please re-generate within Monocle and reinstall'
  exit
end

