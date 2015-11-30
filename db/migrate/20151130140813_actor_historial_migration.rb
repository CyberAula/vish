class ActorHistorialMigration < ActiveRecord::Migration
  def change
    create_table :actor_historial, id: false do |t|
      t.belongs_to :actor, index: true
      t.belongs_to :activity_object, index: true
    end
  end
end
