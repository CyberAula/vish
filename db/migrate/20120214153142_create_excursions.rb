class CreateExcursions < ActiveRecord::Migration
  def change
    create_table :excursions do |t|
      t.timestamps
      t.integer :activity_object_id
      t.text :json
    end
  end
end
