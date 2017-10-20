class AddDraftToDaliDocuments < ActiveRecord::Migration
  def change
  	add_column :dali_documents, :draft, :boolean, :default => true
  end
end
