SocialStream.setup do |config|
  puts "Usando Ruby: #{RUBY_VERSION}"

  # List the models that are social entities. These will have ties between them.
  # Remember you must add an "actor_id" foreign key column to your migration!
  #
  # config.subjects = [:user, :group ]

  # Include devise modules in User. See devise documentation for details.
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :validatable
  config.devise_modules = [:database_authenticatable,
                            :recoverable, :rememberable, :trackable,
                            :omniauthable, :token_authenticatable, :registerable]

  if Vish::Application.config.APP_CONFIG["register_policy"] == "INVITATION_ONLY" || Vish::Application.config.APP_CONFIG["register_policy"] == "HYBRID"
    config.devise_modules << :invitable  
  end

  # Type of activities managed by actors
  # Remember you must add an "activity_object_id" foreign key column to your migration!
  #
  config.objects = [:post, :comment, :document, :link, :excursion, :embed, :writing, :swf, :officedoc, :event, :category, :zipfile, :scormfile, :webapp, :workshop]

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
  config.quick_search_models = [:excursion, :user, :picture, :video, :audio, :swf, :officedoc, :document, :embed, :writing, :link, :event, :zipfile, :scormfile, :webapp, :workshop]
  config.extended_search_models = [:excursion, :user, :event, :workshop, { :resource => [ :picture, :video, :audio, :swf, :officedoc, :document, :embed, :writing, :link, :zipfile, :scormfile, :webapp ] } ]

  # Expose resque interface to manage background tasks at /resque
  #
  #config.resque_access = false

  # Cleditor controls. It is used in new message editor, for example
  # config.cleditor_controls = "bold italic underline strikethrough subscript superscript | size style | bullets | image link unlink"
end
