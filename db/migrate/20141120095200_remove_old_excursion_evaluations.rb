class RemoveOldExcursionEvaluations < ActiveRecord::Migration
  def up
    drop_table :excursion_evaluations
    drop_table :excursion_learning_evaluations
  end

  def down
    create_table :excursion_learning_evaluations do |t|
      t.timestamps
      t.integer :excursion_id
      t.string :ip
      6.times do |ind|
        t.integer "answer_#{ind}".to_sym 
      end
    end

    create_table :excursion_evaluations do |t|
      t.timestamps
      t.integer :excursion_id
      t.string :ip
      6.times do |ind|
        t.integer "answer_#{ind}".to_sym 
      end
    end
  end
end
