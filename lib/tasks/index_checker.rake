namespace :db do
  #Usage
  #Development:   bundle exec rake db:checkDb
  #In production: bundle exec rake db:checkDb RAILS_ENV=production

  task :checkDb => :environment do
        puts "Entra"
          tables = ActiveRecord::Base.connection.tables
          all_foreign_keys = tables.flat_map do |table_name|
            ActiveRecord::Base.connection.columns(table_name).map {|c| [table_name, c.name].join('.') }
          end.select { |c| c.ends_with?('_id') }

          indexed_columns = tables.map do |table_name|
            ActiveRecord::Base.connection.indexes(table_name).map do |index|
              index.columns.map {|c| [table_name, c].join('.') }
            end
          end.flatten

          unindexed_foreign_keys = (all_foreign_keys - indexed_columns)

          if unindexed_foreign_keys.any?
            puts "WARNING: The following foreign key columns don't have an index, which can hurt performance: #{ unindexed_foreign_keys.join(', ') }"
          end
  end
end

