require 'json'

def clean(data)
  return data.encode('UTF-8', invalid: :replace, undef: :replace, replace: '?')
end

class Hash
  def clean_self
    Hash[
      self.collect do |k, v|
        if (v.respond_to?(:to_utf8))
          [ k, v.to_utf8 ]
        elsif (v.respond_to?(:encoding))
          [ k, clean(v.dup) ]
        else
          [ k, v ]
        end
      end
    ]
  end
  
  def to_safe_json
    safe = ''

    begin
      safe = self.to_json
    rescue JSON::GeneratorError => exception
      safe = self.clean_self.to_json
    end

    return safe
  end

end
