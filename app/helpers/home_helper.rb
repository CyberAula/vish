module HomeHelper
  PER_PAGE_IN_HOME = 16

  def current_subject_excursions(options = {})
    subject_excursions current_subject, options
  end

  # Excursions can be search in several scopes:
  # * :me   just the subject
  # * :net  subject and followings
  # * :more everybody except subject and followings
  def subject_excursions(subject, options = {})
    subject_content subject, Excursion, options
  end

  def current_subject_documents(options = {})
    subject_documents current_subject, options
  end

  def subject_documents(subject, options = {})
    subject_content subject, Document, options
  end

  def current_subject_links(options = {})
    subject_links current_subject, options
  end

  def subject_links(subject, options = {})
    subject_content subject, Link, options
  end

  def current_subject_resources(options = {})
    subject_resources current_subject, options
  end

  def subject_resources(subject, options = {})
    subject_content subject, [Document, Embed, Link], options
  end

  def current_subject_categories(options = {})
    subject_categories current_subject, options
  end

  def subject_categories(subject, options = {})
    subject_content subject, Category, options
  end

  def current_subject_events(options = {})
    subject_events current_subject, options
  end

  def subject_events(subject, options = {})
    subject_content subject, Event, options
  end

  def subject_content(subject, klass, options = {})
    options[:limit] ||= 4
    options[:scope] ||= :net
    options[:offset] ||= 0
    options[:page] ||= 0 #page 0 means without pagination

    following_ids = subject.following_actor_ids
    following_ids |= [ subject.actor_id ]

    query = klass
    if klass.is_a?(Array)
      query = ActivityObject.where(:object_type => klass.map{|t| t.to_s})
    else
      query = query.includes(:activity_object)
    end

    case options[:scope]
    when :me
      query = query.authored_by(subject.actor_id)
    when :net
      query = query.authored_by(following_ids)
    when :like
      query = if klass.is_a?(Array)
        Activity.joins(:activity_objects).includes(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => subject.id}).where("activity_objects.object_type IN (?)", klass.map{|k| k.to_s})
      else
        Activity.joins(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => subject.id}).where("activity_objects.object_type = (?)", klass.to_s)
      end
    when :more
      following_ids |= [ subject.actor_id ]
      query = query.not_authored_by(following_ids)
    end

    query = query.where("draft is false") if (klass == Excursion) && (options[:scope] == :net || options[:scope] == :more || (options[:scope] == :me && defined?(current_subject) && subject != current_subject))

    query = query.order('activity_objects.updated_at DESC')
    query = query.limit(options[:limit]) if options[:limit] > 0
    query = query.offset(options[:offset]) if options[:offset] > 0

    # Do not optimize likes. They should go anyways....
    if options[:scope] == :like
      return query.map { |a| a.direct_object }
    end

    # This is the optimization code. It's ugly and *BAD*
    query = if klass.is_a?(Array)
              query.includes(klass.map{ |e| e.to_s.downcase.to_sym} + [:received_actions, { :received_actions => [:actor]}]) 
            else
              query.includes([:activity_object, :received_actions, { :received_actions => [:actor]}]) 
            end

    # pagination, 0 means without pagination
    if options[:page] != 0
      query = query.page(options[:page]).per(PER_PAGE_IN_HOME)
    end

    return query.map{|ao| ao.object} if klass.is_a?(Array)
    query
  end

  


end