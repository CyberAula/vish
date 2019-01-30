class AddContributorsToEdiphy < ActiveRecord::Migration
  def up
    create_table :ediphy_document_contributors do |t|
      t.integer :ediphy_document_id
      t.integer :contributor_id
    end
  end

  def down
    drop_table :ediphy_document_contributors
  end
end
