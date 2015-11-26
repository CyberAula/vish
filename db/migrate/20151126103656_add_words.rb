class AddWords < ActiveRecord::Migration
  def self.up
    create_table :words do |t|
      t.string :value
      t.integer :occurrences, :default => 0
    end
  end

  def self.down
    drop_table :words
  end
end