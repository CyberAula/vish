class RemoveRsEvaluations < ActiveRecord::Migration
  def up
    drop_table "rsevaluations" if ActiveRecord::Base.connection.table_exists? 'rsevaluations'
  end

  def down
  end
end