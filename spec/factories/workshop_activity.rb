include ActionDispatch::TestProcess

# each workshop has N activities -> It can be assignments, wa_gallery, wa_resouyrces, wa_contributions_gallery, wa_text, (they relate wa_type same is wa_id)
Factory.define :workshopActivity do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.workshop {|wshop| wshop.association(:workshop) }
end