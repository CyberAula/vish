class AddImscpsTable < ActiveRecord::Migration
  def change
    create_table "imscpfiles" do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at"
      t.datetime "updated_at"
      t.text     "zipurl"
      t.text     "lourl"
      t.text     "zippath"
      t.text     "lopath"
      t.integer  "width",              :default => 800
      t.integer  "height",             :default => 600
      t.string   "file_file_name"
      t.string   "file_content_type"
      t.integer  "file_file_size"
      t.datetime "file_updated_at"
      t.string   "schema"
      t.string   "schemaversion"
      t.string   "imscp_version"
      t.string   "lohref"
      t.text     "lohrefs"
      t.string   "loresourceurl"
    end
  end
end