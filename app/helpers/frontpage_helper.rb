module FrontpageHelper
  def current_top_actor_excursions
    # We take visits and likes for now...
    Excursion.order{ e.visit_count + (10 * e.like_count) }.first(10)
  end
end
