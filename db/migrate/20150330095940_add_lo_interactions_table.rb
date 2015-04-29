class AddLoInteractionsTable < ActiveRecord::Migration
  def change
    create_table "lo_interactions", :force => true do |t|
      t.integer  "activity_object_id"
      t.datetime "created_at",  :null => false
      t.datetime "updated_at",  :null => false

      t.integer "nsamples"
      t.integer "nvalidsamples"
      
      t.integer "tlo"
      t.integer "tloslide"
      t.integer "tloslide_min"
      t.integer "tloslide_max"
      t.integer "viewedslidesrate"
      t.integer "nvisits"
      t.integer "nclicks"
      t.integer "nkeys"
      t.integer "naq"
      t.integer "nsq"
      t.integer "neq"
      t.integer "acceptancerate"
      t.integer "repeatrate"
      t.integer "favrate"

      t.decimal "x1n", :precision => 12, :scale => 6, :default => 0
      t.decimal "x2n", :precision => 12, :scale => 6, :default => 0
      t.decimal "x3n", :precision => 12, :scale => 6, :default => 0

      t.decimal "interaction_qscore", :precision => 12, :scale => 6, :default => 0
      t.decimal "qscore", :precision => 12, :scale => 6, :default => 0
    end
  end
end
