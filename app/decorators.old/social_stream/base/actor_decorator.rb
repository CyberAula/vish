# Monkey patch Actor to include recommender system
require 'recsys'

Actor.class_eval do
  include RecSys::ActorRecSys
end

