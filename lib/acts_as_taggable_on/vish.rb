# encoding: utf-8

module ActsAsTaggableOn
  class Tag < ::ActiveRecord::Base

    before_save :save_plain_name

    def save_plain_name
      plain_name = I18n.transliterate(self.name, :locale => "en", :replacement => "¿missingTranslation?").downcase rescue self.name
      unless !plain_name.is_a? String or plain_name.blank? or plain_name.include? "¿missingTranslation?"
        self.plain_name = plain_name
      else
        self.plain_name = self.name
      end
    end

  end
end

