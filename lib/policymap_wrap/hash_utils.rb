module PolicyMap
  
  class HashUtils
    
    def self.rename_key!(hash, old_key, new_key)
      hash[new_key] = hash.delete(old_key)
      hash
    end
    
    def self.symbolize_keys(hash)
      hash.inject({}) do |options, (key, value)|
        options[(key.to_sym rescue key) || key] = value
        options
      end
    end

    def self.recursively_symbolize_keys(object)
      if object.is_a? Hash
        symbolized_hash = symbolize_keys(object)
        symbolized_hash.each do |key, value|
          symbolized_hash[key] = recursively_symbolize_keys(value)
        end
        symbolized_hash
      elsif object.is_a? Array
        object.map {|value| recursively_symbolize_keys(value) }
      else
        object
      end
    end
    
  end
  
end
