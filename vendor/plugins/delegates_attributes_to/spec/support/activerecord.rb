ActiveRecord::Schema.define do

  create_table :users do |t|
    t.string :username, :password
    t.belongs_to :contact
    t.timestamps
  end

  create_table :user_defaults do |t|
    t.string :username, :password
    t.belongs_to :contact
    t.timestamps
  end

  create_table :user_no_defaults do |t|
    t.string :username, :password
    t.belongs_to :contact
    t.timestamps
  end

  create_table :user_mixeds do |t|
    t.string :username, :password
    t.belongs_to :contact
    t.timestamps
  end

  create_table :contacts do |t|
    t.string :firstname, :lastname
    t.integer :parent_id, :lft
    t.date :edited_at
  end

  create_table :profiles do |t|
    t.string :about, :hobby
    t.integer :user_id
    t.datetime :changed_at
  end

end
