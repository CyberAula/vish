class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|
      t.timestamps
      t.integer :activity_object_id
      t.text :json
    end
  end
end
