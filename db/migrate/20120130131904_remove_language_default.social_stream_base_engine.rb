# This migration comes from social_stream_base_engine (originally 20120111120920)
class RemoveLanguageDefault < ActiveRecord::Migration
  def up
    change_column_default('users', 'language', nil)
  end

  def down
    change_column_default('users', 'language', 'en')
  end
end
