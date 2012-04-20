module HomeHelper
  def current_subject_excursions(options = {})
    subject_excursions current_subject, options
  end

  # Excursions can be search in several scopes:
  # * :me   just the subjects
  # * :net  subjects and followings
  # * :more everybody except subjects and followings
  def subject_excursions(subject, options = {})
    subject_content subject, Excursion, options
  end

  def current_subject_documents(options = {})
    subject_documents current_subject, options
  end

  def subject_documents(subject, options = {})
    subject_content subject, Document, options
  end

  def subject_content(subject, klass, options = {})
    options[:limit] ||= 4
    options[:scope] ||= :net

    following_ids = subject.following_actor_ids
    following_ids |= [ subject.actor_id ]

    query = klass


    # This is really inefficient. The alternative is using a facet for author:
    # http://freelancing-god.github.com/ts/en/facets.html
    unless options[:query].blank?
      query = query.search(options[:query])
      case options[:scope]
      when :me
        query = query.select{|e| e.author.id == subject.actor_id }
      when :net
        query = query.select{|e| following_ids.include? e.author.id }
      when :more
        query = query.select{|e| not following_ids.include? e.author.id }
      end
      return query.sort_by!{|e| e.created_at}.reverse.first(options[:limit])
    end


    case options[:scope]
    when :me
      query = query.authored_by(subject.actor_id)
    when :net
      query = query.authored_by(following_ids)
    when :more
      query = query.not_authored_by(following_ids)
    end

    query.order('updated_at DESC').first(options[:limit])
  end
end
