class Hash
  def recursive_symbolize_keys
    self.symbolize_keys!
    self.map{|k,v| 
      v.recursive_symbolize_keys if v.is_a? Hash
      v.map!{|e| (e.is_a? Hash) ? e.recursive_symbolize_keys : e } if v.is_a? Array
    }
    self
  end

  def parse_types
    self.each{ |k,v|
      if v.is_a? String
        self[k] = v.to_f if v.is_numeric?
        self[k] = (v.downcase=="true") if v.is_boolean?
      elsif v.is_a? Hash
        self[k] = v.parse_types
      elsif v.is_a? Array
        v.map!{|e| (e.is_a? Hash) ? e.parse_types : ((e.is_a? String) ? (e.is_numeric? ? e.to_f : (e.is_boolean? ? (e.downcase==="true") : e)) : e)}
      end
    }
    self
  end

  def parse_for_vish
    self.recursive_symbolize_keys.parse_types
  end

  def recursive_merge(hash)
    self unless hash.is_a? Hash
    h = {}
    self.each{ |k,v|
      if hash[k].nil?
        h[k] = v
      else
        if v.is_a? Hash and hash[k].is_a? Hash
          h[k] = v.recursive_merge(hash[k])
        else
          h[k] = hash[k]
        end
      end
    }
    hash.each{ |k,v|
      h[k] = v if self[k].nil?
    }
    h
  end
end