class DestroyCustomRelations < ActiveRecord::Migration
  def up
    Relation::Custom.destroy_all
  end

  def down
  end
end
