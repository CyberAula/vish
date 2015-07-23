class AddPrivateStudentGroups < ActiveRecord::Migration
  def up
    create_table :private_student_groups do |t|
      t.integer :owner_id
      t.text :name
      t.text :users_data
      t.timestamps
    end
    add_column :users, :private_student_group_id, :integer
  end

  def down
    remove_column :users, :private_student_group_id
    drop_table :private_student_groups
  end
end
