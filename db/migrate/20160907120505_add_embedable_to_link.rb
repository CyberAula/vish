class AddEmbedableToLink < ActiveRecord::Migration
  def change
    add_column :links, :is_embed, :boolean, :default => false
  end
end
