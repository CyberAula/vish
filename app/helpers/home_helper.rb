module HomeHelper
  def current_actor_excursions
    # TODO: really take the current user excursions
    Excursion.all[0..3]
  end
  def current_actor_documents
    # TODO: really take the current user excursions
    #Document.all[0..3]
  end
end
