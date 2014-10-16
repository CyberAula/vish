module CategoriesHelper
	def get_initial_categories(item)	
		categories_selection_array = []
		item.holder_categories.map { |category| categories_selection_array << category.id }
		categories_selection_array
	end

	def getRootOrderCategories(current)
		n = Actor.find(current).category_order.tr('-','').tr(' ','').tr("'","").split("\n").map(&:to_i)
		n
	end

	def category_thumbnail(category)
		thumbs_array = []
		category.property_objects.each do |item|
			if item.object.class == Picture
				thumbs_array << item.object.file.to_s+"?style=500"
			elsif item.object.class == Excursion
				thumbs_array << excursion_raw_thumbail(item.object)
			elsif item.object.class == Event && !item.object.poster.file_file_name.nil?
				thumbs_array << item.object.poster.file.to_s
			end
		end
		
		result = "<div class='category_thumb'>"
		for i in 0..3
			if thumbs_array[i]
				result += "<div class='category_thumb_"+i.to_s+"'><img src='"+thumbs_array[i]+"'/></div>"
			else
				result += "<div class='category_thumb_"+i.to_s+"'></div>"
			end
		end			
		result += "</div>"
		return raw result
	end
end