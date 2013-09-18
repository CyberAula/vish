module ErrorOnMatcher

  module Rails3

    def errors_on(attribute)
      self.valid?
      [self.errors[attribute]].flatten.compact
    end
    alias :error_on :errors_on

  end

  module Rails2

    def errors_on(attribute)
      self.valid?
      [self.errors.on(attribute)].flatten.compact
    end
    alias :error_on :errors_on

  end

end

if ActiveRecord::VERSION::MAJOR >= 3
  ActiveRecord::Base.module_eval { include ErrorOnMatcher::Rails3 }
else
  ActiveRecord::Base.module_eval { include ErrorOnMatcher::Rails2 }
end
