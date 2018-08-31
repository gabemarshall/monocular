# module Aquatone
#   module Detectors
#     class S3 < Aquatone::Detector
#       self.meta = {
#         :service         => "Azure Cloud App",
#         :service_website => "https://azure",
#         :author          => "Gabe Marshall",
#         :description     => "Cloud App"
#       }

#       CNAME_VALUE          = ".cloudapp.net".freeze
#       RESPONSE_FINGERPRINT = "NoSuchBucket".freeze

#       def run
#         return false unless cname_resource?
#         if resource_value.end_with?(CNAME_VALUE)
#           return get_request("http://#{host}/").body.include?(RESPONSE_FINGERPRINT)
#         end
#         false
#       end
#     end
#   end
# end
