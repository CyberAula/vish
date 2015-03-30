class AddLoInteractionsTable < ActiveRecord::Migration
  def change
    create_table "lo_interactions", :force => true do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false

      t.integer "nsamples"

      t.integer "tlo"
      t.integer "tloslide"
      t.integer "viewedslidesrate"
      t.integer "acceptancerate"
      t.integer "nclicks"
      t.integer "nkeys"
      t.integer "naq"
      t.integer "nsq"
      t.integer "neq"
      t.integer "nvisits"
      t.integer "favrate"
      t.integer "repeatrate"
    end
  end
end
