module HomeHelper
  def current_actor_excursions(limit=4)
    Excursion.authored_by(current_subject).order('updated_at DESC').first(limit)
  end
  def current_actor_documents(limit=4)
    actor_documents
  end

  def actor_documents(actor = current_subject, limit = 4)
    Document.authored_by(actor).order('updated_at DESC').first(limit)
  end
end
