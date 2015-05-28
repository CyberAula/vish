class AddWappTokens < ActiveRecord::Migration
  def up
    create_table :wapp_auth_tokens do |t|
      t.integer :actor_id
      t.string :auth_token
      t.datetime :expire_at
      t.timestamps
    end
  end

  def down
    drop_table :wapp_auth_tokens
  end
end
