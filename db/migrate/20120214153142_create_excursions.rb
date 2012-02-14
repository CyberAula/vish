class CreateExcursions < ActiveRecord::Migration
  def change
    create_table :excursions do |t|

      t.timestamps
    end
  end
end
