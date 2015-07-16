class AddAttachmentAttachmentToExcursions < ActiveRecord::Migration
  def self.up
    change_table :excursions do |t|
      t.attachment :attachment
    end
  end

  def self.down
    drop_attached_file :excursions, :attachment
  end
end
