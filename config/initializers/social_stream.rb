SocialStream.setup do |config|
  # List the models that are social entities. These will have ties between them.
  # Remember you must add an "actor_id" foreign key column to your migration!
  #
  # config.subjects = [:user, :group ]

  # Include devise modules in User. See devise documentation for details.
  # :database_authenticatable is needed even if we have CAS authentication so we add it here
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :validatable
  config.devise_modules = [ :recoverable, :rememberable, :trackable,
                            :omniauthable, :token_authenticatable, :database_authenticatable, :registerable]

  config.devise_modules << :invitable if Vish::Application.config.invitations
  config.devise_modules << :cas_authenticatable if Vish::Application.config.cas

  # Type of activities managed by actors
  # Remember you must add an "activity_object_id" foreign key column to your migration!
  #
  config.objects = [:post, :comment, :document, :link, :excursion, :embed, :writing, :swf, :officedoc, :event, :category, :zipfile, :scormfile, :imscpfile, :webapp, :workshop, :course]

  # Form for activity objects to be loaded
  # You can write your own activity objects
  #
  # config.activity_forms = [ :post, :document, :foo, :bar ]

  # There are not custom relations in the ViSH
  config.custom_relations['user']  = {}
  config.custom_relations['group'] = {}

  # The relation used is Relation::Follow
  config.system_relations = {
    user: [ :follow ],
    group: [ :follow ]
  }

  # Quick search (header) and Extended search models and its order. Remember to create
  # the indexes with thinking-sphinx if you are using customized models.
  #
  # See SocialStream::Search for syntax
  # 
  config.quick_search_models = [:excursion, :user, :picture, :video, :audio, :swf, :officedoc, :document, :category, :embed, :writing, :link, :event, :zipfile, :scormfile, :imscpfile, :webapp, :workshop]
  config.extended_search_models = [:excursion, :user, :event, :category, :workshop, { :resource => [ :picture, :video, :audio, :swf, :officedoc, :document, :embed, :writing, :link, :zipfile, :scormfile, :imscpfile, :webapp ] } ]

  # Expose resque interface to manage background tasks at /resque
  #
  #config.resque_access = false

  # Default notification email settings for new users
  config.default_notification_settings = {
    someone_adds_me_as_a_contact: false,
    someone_confirms_my_contact_request: false,
    someone_likes_my_post: false,
    someone_comments_on_my_post: false
  }
end
