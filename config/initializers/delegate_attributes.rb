# delegate_attributes_to changes the visibility of :changed_attributes
#
# https://github.com/pahanix/delegates_attributes_to/issues/8
class ActiveRecord::Base
  public :changed_attributes
end
