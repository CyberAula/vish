class AddLearningExperience < ActiveRecord::Migration
  def up
  	create_table :excursion_learning_evaluations do |t|
      t.timestamps
      t.integer :excursion_id
      t.string :ip
      6.times do |ind|
        t.integer "answer_#{ind}".to_sym 
      end
    end
  end

  def down
  	drop_table :excursion_learning_evaluations
  end
end
