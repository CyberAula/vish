module HomeHelper
  def current_subject_excursions(options = {})
    subject_excursions current_subject, options
  end

  # Excursions can be search in several scopes:
  # * :me   just the subject
  # * :net  subject and followings
  # * :more everybody except subject and followings
  def subject_excursions(subject, options = {})
    subject_content subject, [Excursion], options
  end

  def current_subject_documents(options = {})
    subject_documents current_subject, options
  end

  def subject_documents(subject, options = {})
    subject_content subject, [Document], options
  end

  def current_subject_links(options = {})
    subject_links current_subject, options
  end

  def subject_links(subject, options = {})
    subject_content subject, [Link], options
  end

  def current_subject_resources(options = {})
    subject_resources current_subject, options
  end

  def subject_resources(subject, options = {})
    subject_content subject, [Document, Embed, Link], options
  end

  def subject_content(subject, klass, options = {})
    options[:limit] ||= 4
    options[:scope] ||= :net
    options[:offset] ||= 0

    following_ids = subject.following_actor_ids
    #following_ids |= [ subject.actor_id ]

    query = ActivityObject.where(:object_type => klass.map{|t| t.to_s})

    case options[:scope]
    when :me
      query = query.authored_by(subject.actor_id)
    when :net
      query = query.authored_by(following_ids)
    when :like
      Activity.joins(:activity_objects).includes(:activity_objects).where({:activity_verb_id => ActivityVerb["like"].id, :author_id => subject.id}).where("activity_objects.object_type IN (?)", klass.map{|k| k.to_s})
    when :more
      following_ids |= [ subject.actor_id ]
      query = query.not_authored_by(following_ids)
    end

    # WARNING: if klass includes Excursion, well.... just don't do it :)
    query = query.joins(:excursion).where("excursions.draft is false") if (klass.include?(Excursion)) and (options[:scope] == :net or options[:scope] == :more or (subject != current_subject and options[:scope] == :me))

    query = query.order('activity_objects.updated_at DESC')
    query = query.limit(options[:limit]) if options[:limit] > 0
    query = query.offset(options[:offset]) if options[:offset] > 0

    query = query.includes(klass.map{ |e| e.to_s.downcase.to_sym} + [:received_actions, { :received_actions => [:actor]}])

    #if options[:scope] == :like
    #  query = query.map { |a| a.activity_objects.first }
    #end

    query.map{|ao| ao.object}
  end
end
