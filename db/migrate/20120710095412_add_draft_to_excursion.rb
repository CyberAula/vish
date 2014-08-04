class AddDraftToExcursion < ActiveRecord::Migration
  def up
    add_column :excursions, :draft, :boolean, :default => false
  end

  def down
    remove_column :excursions, :draft
  end
end
