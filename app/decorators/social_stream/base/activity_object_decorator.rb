# Monkey patch ActivityObject to create update activities (related to drafts
require 'drafts'

ActivityObject.class_eval do
  include Drafts::ActivityObject
end

