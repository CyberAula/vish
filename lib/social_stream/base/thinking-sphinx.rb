module SocialStream
  module Base
    module ThinkingSphinx
      module Index
        module Builder
          def activity_object_index
            indexes activity_object.title,       :as => :title
            indexes activity_object.description, :as => :description
            indexes activity_object.tags.name,   :as => :tags

            has created_at
            has updated_at

            has activity_object.author_actions(:actor_id), :as => :author_id
            has activity_object.owner_actions(:actor_id),  :as => :owner_id
            has activity_object.activity_object_audiences(:relation_id), :as => :relation_ids

            has activity_object.like_count, :as => :like_count, :type => :integer, :sortable => true
            has activity_object.visit_count, :as => :visit_count, :type => :integer, :sortable => true
            has activity_object.download_count, :as => :download_count, :type => :integer, :sortable => true

            has activity_object.title_length, :as => :title_length, :type => :integer, :sortable => true
            has activity_object.desc_length, :as => :desc_length, :type => :integer, :sortable => true
            has activity_object.tags_length, :as => :tags_length, :type => :integer, :sortable => true

            has activity_object.popularity, :as => :popularity, :sortable => true
            has activity_object.qscore, :as => :qscore, :sortable => true
            has activity_object.ranking, :as => :ranking, :sortable => true

            #Thinking Sphinx cannot filter by 'string' attributes (like language).
            #So, we will use the CRC32 codification of the string, which is an integer. This way, we have to search for crc32 code instead of the string itself. To search for the language "en", we have to search for "en".to_crc32.
            #This is done in a different way according to the database (MySQL or PostgreSQL). See http://www.coderexception.com/CNuH6z16USXyQSUy/using-crc32-tweak-on-hasmany-relations-in-thinking-sphinx for mroe info.
            if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
              #CRC32 is not a native function in PostgreSQL, and so you may need to add it yourself. Thinking Sphinx prior to v3 do this for you.
              has "array_to_string(array_agg(CRC32(activity_objects.language)), ',')", :as => :language, :type => :multi
            elsif ActiveRecord::Base.connection.adapter_name == "Mysql2" or ActiveRecord::Base.connection.adapter_name == "MySQL"
              has "GROUP_CONCAT(CRC32(activity_objects.language) SEPARATOR ',')", :as => :language, :type => :integer, :multi => true
            else
              has activity_object.language, :as => :language
            end
          end
        end
      end
    end
  end
end