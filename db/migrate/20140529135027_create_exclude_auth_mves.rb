class CreateExcludeAuthMves < ActiveRecord::Migration
  def change
    create_table :exclude_auth_mves do |t|
      t.integer :id
      t.string :authName
      t.integer :rankTime, :default => 0 

      t.timestamps
    end
  end
end
