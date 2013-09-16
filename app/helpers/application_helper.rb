module ApplicationHelper
	def categories_select(select_id, item)
	  categories = subject_categories(current_subject, {:scope => :me, :limit => 0})
	  subject_categories_array = categories.map { |category| [category.title, category.id] }.sort_by! {|cat| cat[0]} 
	  categories_selection_array = [] 
	  item.holder_categories.map { |category| categories_selection_array << category.id }
	  select_tag(select_id, options_for_select(subject_categories_array, categories_selection_array), {:multiple => true, :style => 'width: 125px' })
	end


	def popular_excursions(number=10)
		# We take visits and likes for now...
    	Excursion.joins(:activity_object).where("draft is false").order("activity_objects.visit_count + (10 * activity_objects.like_count) DESC").first(number)
	end

	def popular_resources(number=10)
		ActivityObject.where(:object_type => [Document, Embed, Link].map{|t| t.to_s}).first(number).map{|ao| ao.object}
	end
end
