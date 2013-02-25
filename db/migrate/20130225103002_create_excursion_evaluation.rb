class CreateExcursionEvaluation < ActiveRecord::Migration
  def up
    create_table :excursion_evaluations do |t|
      t.timestamps
      t.integer :excursion_id
      t.string :ip
      5.times do |ind|
        t.integer "answer_#{ind}".to_sym 
      end
    end
  end

  def down
    drop_table :excursion_evaluations
  end
end
