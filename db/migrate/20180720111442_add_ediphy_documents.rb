class AddEdiphyDocuments < ActiveRecord::Migration
  def change
    create_table :ediphy_documents do |t|
      t.integer  "activity_object_id"
      t.text     "json"
      t.boolean  "draft", :default => true
      t.timestamps
    end
  end
end