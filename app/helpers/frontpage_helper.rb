module FrontpageHelper
  def current_top_actor_excursions
    # We take visits for now...
    Excursion.order{ e.visit_count }.first(10)
  end
end
