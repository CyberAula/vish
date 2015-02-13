class OrderListInCat < ActiveRecord::Migration
  def up
  	add_column :users, :order_list_in_cat, :boolean
  end

  def down
  	remove_column :users, :order_list_in_cat
  end
end
