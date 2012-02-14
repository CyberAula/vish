class CreateSlides < ActiveRecord::Migration
  def change
    create_table :slides do |t|

      t.timestamps
    end
  end
end
