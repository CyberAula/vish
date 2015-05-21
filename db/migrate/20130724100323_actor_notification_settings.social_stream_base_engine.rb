# This migration comes from social_stream_base_engine (originally 20130723133530)
class ActorNotificationSettings < ActiveRecord::Migration
  def change
    change_table :actors do |t|
      t.string "notification_settings"
    end
  end
end
