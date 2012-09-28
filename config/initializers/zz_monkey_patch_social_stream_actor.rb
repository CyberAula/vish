# Monkey patch Actor to include recommender system
require 'recsys'
ActiveSupport.on_load :actor do
  include RecSys::Actor
end

