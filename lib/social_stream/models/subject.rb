module SocialStream
  module Models
    # {Subject Subjects} are subtypes of {Actor Actors}. {SocialStream Social Stream} provides two
    # {Subject Subjects}, {User} and {Group}
    #
    # Each {Subject} must defined in +config/initializers/social_stream.rb+ in order to be
    # included in the application.
    #
    # = Scopes
    # There are several scopes available for subjects 
    #
    # alphabetic:: sort subjects by name
    # name_search:: simple search by name
    # distinct_initials:: get only the first letter of the name
    # followed:: sort by most following incoming {Tie ties}
    # liked:: sort by most likes
    #
    module Subject
      extend ActiveSupport::Concern

      included do
        subtype_of :actor,
                   :build => { :subject_type => to_s }
        
        has_one :activity_object, :through => :actor
        has_one :profile, :through => :actor
        
        validates_presence_of :name
        
        accepts_nested_attributes_for :profile
        
        scope :alphabetic, joins(:actor).merge(Actor.alphabetic)

        scope :letter, lambda{ |param|
          joins(:actor).merge(Actor.letter(param))
        }

        scope :name_search, lambda{ |param|
          joins(:actor).merge(Actor.name_search(param))
        }
        
        scope :tagged_with, lambda { |param|
          if param.present?
            joins(:actor => :activity_object).merge(ActivityObject.tagged_with(param))
          end
        }

        scope :distinct_initials, joins(:actor).merge(Actor.distinct_initials)

        scope :followed, lambda { 
          joins(:actor).
            merge(Actor.followed)
        }

        scope :liked, lambda { 
          joins(:actor => :activity_object).
            order('activity_objects.like_count DESC')
        }

        scope :most, lambda { |m|
          types = %w( followed liked )

          if types.include?(m)
            __send__ m
          end
        }

        scope :recent, -> {
          order('groups.updated_at DESC')
        }
  
        define_index do
          indexes actor.name, :sortable => true
          indexes actor.email
          indexes actor.slug
          
          has created_at
          has updated_at

          has id
          has activity_object.id, :as => :activity_object_id, :type => :integer

          has activity_object.popularity, :as => :popularity, :sortable => true
          has activity_object.qscore, :as => :qscore, :sortable => true
          has activity_object.ranking, :as => :ranking, :sortable => true
          
          has activity_object.activity_object_audiences(:relation_id), :as => :relation_ids
          has activity_object.scope, :as => :scope, :type => :integer

          has activity_object.title_length, :as => :title_length, :type => :integer, :sortable => true
          has activity_object.desc_length, :as => :desc_length, :type => :integer, :sortable => true
          has activity_object.tags_length, :as => :tags_length, :type => :integer, :sortable => true

          has activity_object.tags(:id), :as => :tag_ids
          
          has activity_object.age_min, :type => :integer, :sortable => true
          has activity_object.age_max, :type => :integer, :sortable => true

          
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
      
      module ClassMethods
        def find_by_slug(perm)
          includes(:actor).where('actors.slug' => perm).first
        end
        
        def find_by_slug!(perm)
          find_by_slug(perm) ||
            raise(ActiveRecord::RecordNotFound)
        end 

        # The types of actors that appear in the contacts/index
        #
        # You can customize this in each class
        def contact_index_models
          SocialStream.contact_index_models
        end
      end

      def to_param
        slug
      end
    end
  end
end
