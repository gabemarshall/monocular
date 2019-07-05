require 'yaml'

my_array = []

Dir[File.join(File.dirname(__FILE__), "", "rule.rb")].each do |collector|
  raw_rule = File.read collector
  #rule = YAML.load raw_rule
  #my_array.push(rule)
  rule = eval(raw_rule)
end

puts my_array
# $db_file = 'sc_config.yml'

# def load_data
#   begin
#     text = File.read $db_file
#   rescue exception
#     puts "Missing sc_config.yml, please see README.md for instructions on setting up shellcreeper"
#   end
#   return YAML.load text
# end

# def store_data(hash)
#   f = File.open($db_file, 'w')
#   f.write hash.to_yaml
#   f.close
# end

# foo = load_data()
# foo["secret"] = "fSDXsfadsfsdfSR"
# puts foo

# store_data(foo)