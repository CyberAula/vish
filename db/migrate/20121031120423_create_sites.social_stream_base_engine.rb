# This migration comes from social_stream_base_engine (originally 20121031111857)
class CreateSites < ActiveRecord::Migration
  def change
    create_table :sites do |t|
      t.text :config

      t.timestamps
    end
  end
end
