class AddStreamingToEvents < ActiveRecord::Migration
  def change
    change_table :events do |t|
      t.boolean :streaming, default: false
    end
  end
end
