class TrackingSystemEntry < ActiveRecord::Base

  validates :app_id,
  :presence => true

  validates :data,
  :presence => true

end