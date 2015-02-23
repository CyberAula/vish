class RemoveMve < ActiveRecord::Migration
  def up
	if column_exists? :excursions, :mve
		remove_column :excursions, :mve
	end
	if column_exists? :excursions, :is_mve
		remove_column :excursions, :is_mve
	end
	if column_exists? :excursions, :rankMve
		remove_column :excursions, :rankMve
	end
	if column_exists? :actors, :mve
		remove_column :actors, :mve
	end
	if column_exists? :actors, :is_mve
		remove_column :actors, :is_mve
	end
	if column_exists? :actors, :rankMve
		remove_column :actors, :rankMve
	end

	if ActiveRecord::Base.connection.table_exists? 'exclude_auth_mves'
		drop_table "exclude_auth_mves"
	end

	if ActiveRecord::Base.connection.table_exists? 'exclude_exc_mves'
		drop_table "exclude_exc_mves"
	end

  end

  def down
  end
end
