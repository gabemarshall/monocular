require 'json'

class Hash
  def clean
    Hash[
      self.collect do |k, v|
        if (v.respond_to?(:to_utf8))
          [ k, v.to_utf8 ]
        elsif (v.respond_to?(:encoding))
          [ k, v.dup.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?') ]
        else
          [ k, v ]
        end
      end
    ]
  end
  
  def to_safe_json
    return self.clean.to_json
  end

end