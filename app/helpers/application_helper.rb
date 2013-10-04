module ApplicationHelper
	def categories_select(select_id, item)
	  categories = subject_categories(current_subject, {:scope => :me, :limit => 0})
	  subject_categories_array = categories.map { |category| [category.title, category.id] }.sort_by! {|cat| cat[0]} 
	  categories_selection_array = [] 
	  item.holder_categories.map { |category| categories_selection_array << category.id }
	  select_tag(select_id, options_for_select(subject_categories_array, categories_selection_array), {:multiple => true })
	end


	def popular_excursions(number=10)
		# We take visits and likes for now...
    	Excursion.joins(:activity_object).where("draft is false").order("activity_objects.visit_count + (10 * activity_objects.like_count) DESC").first(number)
	end

	def popular_resources(number=10)
		ActivityObject.where(:object_type => [Document, Embed, Link].map{|t| t.to_s}).first(number).map{|ao| ao.object}
	end

	def category_thumbnail(category)
		default_thumb = link_to "<i class='icon-th-large'></i>".html_safe, category, :title => category.title

		if category.property_objects.count < 2
			return default_thumb
		end
		thumbs_array = []
		category.property_objects.each do |item|
			if item.object.class == Picture
				thumbs_array << item.object.file.to_s+"?style=500"
			elsif item.object.class == Excursion
				thumbs_array << excursion_raw_thumbail(item.object)
			elsif item.object.class == Event
				thumbs_array << item.object.poster
			end
		end

		if thumbs_array.size < 2
			return default_thumb
		else
			result = "<div class='category_thumb'>"
			for i in 0..3
				if thumbs_array[i]
					result += "<span class='category_thumb_"+i.to_s+"'><img href='"+thumbs_array[i]+"'/></span>"
				else
					result += "<span class='category_thumb_"+i.to_s+"'></span>"
				end
			end			
			result += "</div>"
			return raw result
		end


	end
end
