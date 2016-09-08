class AddIdToActorHistorial < ActiveRecord::Migration
  def change
    add_column :actor_historial, :id, :primary_key
  end
end
