module Wa
  def acts_as_wa
    include InstanceMethods
    ############################ Class methods ################################
    has_one :workshop_activity, :as => :wa, :autosave => true, :dependent => :destroy
    alias_method_chain :workshop_activity, :build
    
    if ActiveRecord::Base.connection.table_exists? "workshop_activities"
      workshop_activity_attributes = WorkshopActivity.content_columns.map(&:name) #<-- gives access to all columns of WorkshopActivity
    else
      workshop_activity_attributes = []
    end

    # define the attribute accessor method
    def wa_attr_accessor(*attribute_array)
      attribute_array.each do |att|
        define_method(att) do
          workshop_activity.send(att)
        end
        define_method("#{att}=") do |val|
          workshop_activity.send("#{att}=",val)
        end
      end
    end
    wa_attr_accessor *workshop_activity_attributes #<- delegating the attributes
  end
 
  module InstanceMethods
    def workshop_activity_with_build
      workshop_activity_without_build || build_workshop_activity
    end
  end
end