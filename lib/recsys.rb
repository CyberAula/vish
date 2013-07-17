module RecSys
  module ActorRecSys
    
    def contact_suggestions(size=1)
      if Site.current.config[:recommender_system] and Site.current.config[:recommender_system]==true
        return rec_contact_suggestions(size)
      else
        return Contact.last(size)
      end
    end

    def rec_contact_suggestions(size=1)
      sgs = (
       RecsysUser.
         find_all_by_id(id).
         map { |u| RecsysUser.find_all_by_clusterid(u.clusterid) }.
         flatten.
         sort_by!{ |u| u.position}.
         map{ |u| u.actor }.
         compact &
       Actor.
         where('id NOT IN (?)', (sent_active_contact_ids + [id]))
      ).first(size).map { |a| contact_to! a }

      candidates = Actor.where('id NOT IN (?)', (sent_active_contact_ids + [id]))

      sgs + (size - sgs.size).times.map {
        candidates.delete_at rand(candidates.size)
      }.compact.map { |a|
        contact_to! a
      }
    end

    def excursion_suggestions(size=4)
      if Site.current.config[:recommender_system] and Site.current.config[:recommender_system]==true
        excursions = rec_excursion_suggestions(size)
      else
        excursions = Excursion.last(size)
      end

      rec_excursions = [];

      #remove user excursions and drafts
      excursions.each do |ex|
        if (!(defined? current_subject).nil? && ex.author.subject == current_subject) || ex.draft
          next
        end
        rec_excursions.push(ex)
      end

      #Avoid empty data
      if rec_excursions.length == 0
        rec_excursions = Excursion.last(size)
      end

      return rec_excursions
    end

    def rec_excursion_suggestions(size=4)
      sgs = (
       RecsysUser.
         find_all_by_id(id).
         map { |u| RecsysLearningObject.find_all_by_clusterid(u.clusterid) }.
         flatten.
         select { |lo| lo.type == "Excursion" }.
         sort_by!{ |lo| lo.position}.
         map{ |lo| lo.activity_object }.
         compact.
         map { |ao| ao.object }
      ).select { |e| e.is_a? Excursion } .first(size)
      # TODO: Filter by consummed resources
      sgs
    end

    def resource_suggestions(size=6)
      if Site.current.config[:recommender_system] and Site.current.config[:recommender_system]==true
        return rec_resource_suggestions(size)
      else
        return Document.last(size)
      end
    end

    def rec_resource_suggestions(size=6)
      sgs = (
       RecsysUser.
         find_all_by_id(id).
         map { |u| RecsysLearningObject.find_all_by_clusterid(u.clusterid) }.
         flatten.
         select { |lo| lo.type == "Document" or lo.type == "Link" or lo.type == "Embed" }.
         sort_by!{ |lo| lo.position}.
         map{ |lo| lo.activity_object }.
         compact.
         map { |ao| ao.object }
      ).select { |e| e.is_a? Document or e.is_a? Link or e.is_a? Embed } .first(size)
      # TODO: Filter by consummed resources
      sgs
    end

  end
end

