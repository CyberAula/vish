class Contact < ActiveRecord::Base
  def fullname
    firstname + ' ' + lastname
  end
end

class Profile < ActiveRecord::Base  
end

class User < ActiveRecord::Base
  has_one :profile
  delegate_attributes :to => :profile
end

class Profile < ActiveRecord::Base
  belongs_to :user
  delegate_attributes :to => :user
end

class UserAutosaveOff < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact, :autosave => false
  delegate_attributes :to => :contact
  
  has_one :profile, :autosave => false
  delegate_attributes :to => :profile
end

class UserDefault < ActiveRecord::Base
  delegate_belongs_to :contact
  delegate_has_one :profile, :foreign_key => 'user_id'
end

class UserDeprecated < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  has_one :profile
end

class UserDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :to => :contact
end

class UserMixed < ActiveRecord::Base
  delegate_belongs_to :contact, :defaults, :fullname
end

class UserNoDefault < ActiveRecord::Base
  delegate_belongs_to :contact, :fullname
end

class UserPartiallyDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :firstname, :to => :contact
end

class UserWithDelegatedTimeAttribute < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attribute :edited_at, :to => :contact
  
  has_one :profile, :foreign_key => 'user_id'
  delegate_attribute :changed_at, :to => :profile
end

class UserWithFirstnameValidation < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :to => :contact
  validates_presence_of :firstname
end
