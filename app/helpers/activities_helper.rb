module ActivitiesHelper
  # Link to 'like' or 'unlike' depending on the like status of the activity to current_subject
  #
  # @param [Object]
  # @return [String]
  def link_like(object, options={})
    options[:size] ||= :small
    params = link_like_params(object, options)
    link_to params[0],params[1],params[2]
  end

  def link_like_params(object,options)
    params = Array.new
    if !user_signed_in?
      params << if options[:size] == :small
                  image_tag("star-off10.png", :class => "menu_icon")
                else
                  image_tag("star-off.png", :class => "menu_icon") + t('follow.add_favorite')
                end
      params << new_user_session_path
      params << {:class => "verb_like like_size_" + options[:size].to_s,:id => "like_" + dom_id(object)}
    else
      if (object.liked_by?(current_subject))
        params << if options[:size] == :small
                    image_tag("star-on10.png", :class => "menu_icon")
                  else
                    image_tag("star-on.png", :class => "menu_icon") + t('follow.is_favorite')
                  end
        params << url_for(object) + '/like?size=' + options[:size].to_s
        params << {:class => "verb_like",:id => "like_" + dom_id(object),:method => :delete, :remote => true}
      else
        params << if options[:size] == :small
                    image_tag("star-off10.png", :class => "menu_icon")
                  else
                    image_tag("star-off.png", :class => "menu_icon") + t('follow.add_favorite')
                  end
        params << url_for(object) + '/like?size=' + options[:size].to_s
        params << {:class => "verb_like",:id => "like_" + dom_id(object),:method => :post, :remote => true}
      end
    end
  end

  # Build a new post based on the current_subject. Useful for authorization queries
  def new_post(receiver)
    return Post.new unless user_signed_in?

    Post.new :author_id => Actor.normalize_id(current_subject),
             :owner_id  => Actor.normalize_id(receiver)
  end
end
