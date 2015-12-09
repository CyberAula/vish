class AddRsevaluations < ActiveRecord::Migration
  def change
    create_table :rsevaluations do |t|
      t.integer :actor_id
      t.text :data
      t.string :status, :default => "0"
      t.timestamps null: false
    end
  end
end
