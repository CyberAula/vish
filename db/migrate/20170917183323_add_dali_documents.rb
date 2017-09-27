class AddDaliDocuments < ActiveRecord::Migration
  def change
  	create_table :dali_documents do |t|
  		t.string "title"
    	t.datetime "created_at",				:null => false
    	t.datetime "updated_at",				:null => false
    	t.integer  "activity_object_id"
		t.text     "json"
    	t.timestamps
	end
	
	create_table :dali_exercises do |t|
	    t.integer  "dali_document_id"
	    t.text     "xml"
	    t.datetime "created_at",       :null => false
	    t.datetime "updated_at",       :null => false
	end	
  
  end
end
