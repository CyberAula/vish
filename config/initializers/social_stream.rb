SocialStream.setup do |config|
  # List the models that are social entities. These will have ties between them.
  # Remember you must add an "actor_id" foreign key column to your migration!
  #
  # config.subjects = [:user, :group ]

  # Include devise modules in User. See devise documentation for details.
  # Others available are:
  # :confirmable, :lockable, :timeoutable, :validatable
  # config.devise_modules = :database_authenticatable, :registerable,
  #                         :recoverable, :rememberable, :trackable,
  #                         :omniauthable, :token_authenticatable
  
  # Type of activities managed by actors
  # Remember you must add an "activity_object_id" foreign key column to your migration!
  #
  config.objects = [ :post, :comment, :document, :link, :excursion, :slide ]
  
  # Form for activity objects to be loaded 
  # You can write your own activity objects
  #
  # config.activity_forms = [ :post, :document, :foo, :bar ]
  
  # Config the relation model of your network
  #
  # :custom - users define their own relation types, and post with privacy, like Google+
  # :follow - user just follow other users, like Twitter
  #
  config.relation_model = :follow

  # Quick search (header) and Extended search models and its order. Remember to create
  # the indexes with thinking-sphinx if you are using customized models.
  # 
  # config.quick_search_models = [:user, :group]
  # config.extended_search_models = [:user, :group]

  # Cleditor controls. It is used in new message editor, for example
  # config.cleditor_controls = "bold italic underline strikethrough subscript superscript | size style | bullets | image link unlink"
end

module SocialStream::Views::Toolbar
  def toolbar_items type, options = {}
    case type
    when :home
      []
    when :profile
      SocialStream::Views::List.new.tap do |items|
        subject = options[:subject]
        raise "Need a subject options for profile toolbar" if subject.blank?

        #logo
        items << {
          :key => :logo,
          :html => render(:partial => 'toolbar/logo', :locals => { :subject => subject })
        }

        #Information button
        items << {
          :key => :subject_info,
          :html => link_to(t('menu.information'), [subject, :profile])
        }

        #Resources brief
        items << {
          :key => :resources,
          :html => render(:partial => 'toolbar/resources', :locals => { :subject => subject })
        }
      end
    when :messages
      super
    end
  end
end
