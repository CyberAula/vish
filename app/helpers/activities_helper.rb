module ActivitiesHelper
  # Link to 'like' or 'unlike' depending on the like status of the activity to current_subject
  #
  # @param [Object]
  # @return [String]
  def link_like(object)
    params = link_like_params(object)
    link_to params[0],params[1],params[2]
  end

  def link_like_params(object)
    params = Array.new
    if !user_signed_in?
      params << t('activity.like')
      params << new_user_session_path
      params << {:class => "verb_like",:id => "like_" + dom_id(object)}
    else
      if (object.liked_by?(current_subject))
        params << t('activity.unlike')
        params << [object, :like]
        params << {:class => "verb_like",:id => "like_" + dom_id(object),:method => :delete, :remote => true}
      else
        params << t('activity.like')
        params << [object, :like]
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
