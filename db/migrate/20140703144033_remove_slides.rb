class RemoveSlides < ActiveRecord::Migration
  def up
  	drop_table :slides
  end

  def down
  	create_table :slides do |t|
      t.timestamps
      t.integer :activity_object_id
      t.text :json
    end
  end
end