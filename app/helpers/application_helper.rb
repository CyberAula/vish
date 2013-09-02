module ApplicationHelper
	def categories_select(select_id, item)
	  categories = subject_categories(current_subject, {:scope => :me, :limit => 0})
	  subject_categories_array = categories.map { |category| [category.title, category.id] }.sort_by! {|cat| cat[0]} 
	  categories_selection_array = [] 
	  item.holder_categories.map { |category| categories_selection_array << category.id }
	  select_tag(select_id, options_for_select(subject_categories_array, categories_selection_array), {:multiple => true, :style => 'width: 125px' })
	end

end
