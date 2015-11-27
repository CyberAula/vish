# encoding: utf-8

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base

    before_save :save_plain_name

    def save_plain_name
      self.plain_name = ActsAsTaggableOn::Tag.getPlainName(self.name)
    end

    def self.getPlainName(name)
      plain_name = I18n.transliterate(name, :locale => "en", :replacement => "¿missingtranslation?").downcase rescue name
      plain_name = name if !plain_name.is_a? String or plain_name.blank? or plain_name.include? "¿missingtranslation?"
      return plain_name
    end

  end
end

