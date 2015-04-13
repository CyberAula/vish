include ActionDispatch::TestProcess

Factory.define :waContributionsGallery do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.workshop {|wshop| wshop.association(:workshop) }
end