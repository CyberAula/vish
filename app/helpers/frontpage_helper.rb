module FrontpageHelper
  def current_top_actor_excursions
    # TODO: really take the top 10 excursions
    Excursion.all[0..8]
  end
end
