module HomeHelper
  def current_actor_excursions
    Excursion.authored_by(current_subject).first(4)
  end
  def current_actor_documents
    Document.authored_by(current_subject).first(4)
  end
end
