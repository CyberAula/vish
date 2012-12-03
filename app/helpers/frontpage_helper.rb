module FrontpageHelper
  def current_top_actor_excursions
    # We take visits and likes for now...
    Excursion.joins(:activity_object).order("activity_objects.visit_count + (10 * activity_objects.like_count) DESC").first(10)
  end
end
