class AddDraftToEdiphyDocuments < ActiveRecord::Migration
  def change
  	add_column :ediphy_documents, :draft, :boolean, :default => true
  end
end
