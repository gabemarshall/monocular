require "resolv"
require "ipaddr"
require "socket"
require "timeout"
require "shellwords"
require "optparse"

require "httparty"
require "childprocess"

require_relative("aquatone/version")
require_relative("aquatone/port_lists")
require_relative("aquatone/url_maker")
require_relative("aquatone/validation")
require_relative("aquatone/thread_pool")
require_relative("aquatone/http_client")
require_relative("aquatone/browser")
require_relative("aquatone/browser/drivers/nightmare")
require_relative("aquatone/domain")
require_relative("aquatone/resolver")
require_relative("aquatone/assessment")
require_relative("aquatone/report")
require_relative("aquatone/command")
require_relative("aquatone/collector")
require_relative("aquatone/detector")

module Aquatone
  AQUATONE_ROOT         = File.expand_path(File.join(File.dirname(__FILE__), "..")).freeze
  DEFAULT_AQUATONE_PATH = File.join(Dir.home, "aquatone").freeze

  def self.aquatone_path
    ENV['AQUATONEPATH'] || DEFAULT_AQUATONE_PATH
  end
end

require_relative("aquatone/key_store")

Dir[File.join(File.dirname(__FILE__), "aquatone", "collectors", "*.rb")].each do |collector|
  require collector
end

Dir[File.join(File.dirname(__FILE__), "aquatone", "detectors", "*.rb")].each do |detector|
  require detector
end

require_relative("aquatone/commands/discover")
require_relative("aquatone/commands/scan")
require_relative("aquatone/commands/gather")
require_relative("aquatone/commands/takeover")
