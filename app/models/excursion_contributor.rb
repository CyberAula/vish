class ExcursionContributor < ActiveRecord::Base
  belongs_to :excursion
  belongs_to :contributor, :class_name => "Actor"
end

