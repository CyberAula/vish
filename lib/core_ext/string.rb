class String
  def is_numeric?
    true if Float(self) rescue false
  end

  def is_boolean?
    ["true","false"].include?(self.downcase)
  end

  # Patch for Rails 4
  # def to_crc32
  #   require 'zlib'
  #    Zlib::crc32(self)
  # end
end