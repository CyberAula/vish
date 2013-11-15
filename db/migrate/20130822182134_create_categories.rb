class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.references :activity_object
      t.timestamps
    end
  end
end
