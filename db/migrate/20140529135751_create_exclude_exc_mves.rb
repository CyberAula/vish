class CreateExcludeExcMves < ActiveRecord::Migration
  def change
    create_table :exclude_exc_mves do |t|
      t.integer :id
      t.string :excName
      t.integer :rankTime, :default => 0

      t.timestamps
    end
  end
end
