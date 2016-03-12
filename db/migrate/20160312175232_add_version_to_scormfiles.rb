class AddVersionToScormfiles < ActiveRecord::Migration
  def change
    add_column :scormfiles, :schema, :string
    add_column :scormfiles, :schemaversion, :string
    add_column :scormfiles, :scorm_version, :string
  end
end