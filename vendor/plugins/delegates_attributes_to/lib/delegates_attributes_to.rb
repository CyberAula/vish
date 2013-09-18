module DelegatesAttributesTo

  DEFAULT_REJECTED_COLUMNS = ['created_at','created_on','updated_at','updated_on','lock_version','type','id','position','parent_id','lft','rgt'].freeze
  DIRTY_SUFFIXES = ["_changed?", "_change", "_will_change!", "_was"].freeze

  def self.included(base)
    base.extend ClassMethods
    base.send :include, InstanceMethods

    base.alias_method_chain :assign_multiparameter_attributes, :delegation

    base.class_attribute :default_rejected_delegate_columns
    base.default_rejected_delegate_columns = DEFAULT_REJECTED_COLUMNS.dup

    base.class_attribute :delegated_attributes
    base.delegated_attributes = HashWithIndifferentAccess.new
  end

  module ClassMethods

    ATTRIBUTE_SUFFIXES = (['', '=', '?'] + DIRTY_SUFFIXES).freeze

    # has_one :profile
    # delegate_attributes :to => :profile
    def delegate_attributes(*attributes)
      options = attributes.extract_options!
      unless options.is_a?(Hash) && association = options[:to]
        raise ArgumentError, "Delegation needs a target. Supply an options hash with a :to key as the last argument (e.g. delegate_attribute :hello, :to => :greeter"
      end
      prefix = options[:prefix] && "#{options[:prefix] == true ? association : options[:prefix]}_"
      reflection = reflect_on_association(association)
      raise ArgumentError, "Unknown association #{association}" unless reflection

      reflection.options[:autosave] = true unless reflection.options.has_key?(:autosave)

      if attributes.empty? || attributes.delete(:defaults)
        attributes += reflection.klass.column_names - default_rejected_delegate_columns
      end

      self.delegated_attributes = self.delegated_attributes.dup

      attributes.each do |attribute|
        delegated_attributes.merge!("#{prefix}#{attribute}" => [association, attribute])

        ATTRIBUTE_SUFFIXES.each do |suffix|
          define_method("#{prefix}#{attribute}#{suffix}") do |*args|
            association_object = send(association) || send("build_#{association}")
            association_object.send("#{attribute}#{suffix}", *args)
          end
        end
      end
    end

    alias_method :delegate_attribute,   :delegate_attributes
    alias_method :delegates_attribute,  :delegate_attributes
    alias_method :delegates_attributes, :delegate_attributes

    def delegate_belongs_to(association, *args)
      delegate_association(:belongs_to, association, *args)
    end

    def delegate_has_one(association, *args)
      delegate_association(:has_one, association, *args)
    end

    def delegates_attributes_to(association, *args)
      warn "delegates_attributes_to is deprecated use delegate_attributes :to => association syntax"
      options = args.extract_options!
      options[:to] = association
      args << options
      delegate_attributes(*args)
    end

    private

      def delegate_association(macro, association, *args)
        options = args.extract_options!
        # assosiation reflection doesn't ignore prefix option and raises ArgumentError
        prefix = options.delete(:prefix)
        send(macro, association, options) unless reflect_on_association(association)
        options[:to] = association
        # give back prefix option
        options[:prefix] = prefix
        args << options
        delegate_attributes(*args)
      end
  end

  module InstanceMethods

    private

      def assign_multiparameter_attributes_with_delegation(pairs)
        delegated_pairs = {}
        original_pairs  = []

        pairs.each do |name, value|
          # it splits multiparameter attribute
          # 'published_at(2i)'  => ['published_at(2i)', 'published_at', '(2i)']
          # 'published_at'      => ['published_at',     'published_at',  nil  ]
          __, delegated_attribute, suffix = name.match(/^(\w+)(\([0-9]*\w\))?$/).to_a
          association, attribute = self.class.delegated_attributes[delegated_attribute]

          if association
            (delegated_pairs[association] ||= {})["#{attribute}#{suffix}"] = value
          else
            original_pairs << [name, value]
          end
        end

        delegated_pairs.each do |association, attributes|
          association_object = send(association) || send("build_#{association}")
          # let association_object handle its multiparameter attributes
          association_object.attributes = attributes
        end

        assign_multiparameter_attributes_without_delegation(original_pairs)
      end

      def changed_attributes
        result = {}
        self.class.delegated_attributes.each do |delegated_attribute, (association, attribute)|
          # If an association isn't loaded it hasn't changed at all. So we skip it.
          # If we don't skip it and have mutual delegation beetween 2 models
          # we get SystemStackError: stack level too deep while trying to load
          # a chain like user.profile.user.profile.user.profile...
          next unless association(association).loaded?
          # skip if association object is nil
          next unless association_object = send(association)
          # call private method #changed_attributes
          association_changed_attributes = association_object.send(:changed_attributes)
          # next if attribute hasn't been changed
          next unless association_changed_attributes.has_key?(attribute.to_s)

          result.merge! delegated_attribute => association_changed_attributes[attribute]
        end
        changed_attributes = super
        changed_attributes.merge!(result)
        changed_attributes
      end
  end
end

DelegateBelongsTo = DelegatesAttributesTo unless defined?(DelegateBelongsTo)

ActiveRecord::Base.send :include, DelegatesAttributesTo
