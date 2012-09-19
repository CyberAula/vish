class AddExcursionContributors < ActiveRecord::Migration
  def up
    create_table :excursion_contributors do |t|
      t.integer :excursion_id
      t.integer :contributor_id
    end
  end

  def down
    drop_table :excursion_contributors
  end
end
