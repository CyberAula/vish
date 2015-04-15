include ActionDispatch::TestProcess

Factory.define :trackingSystemEntry do |u|
	u.sequence(:app_id) { |n| "app_id#{ n }" }
 	u.sequence(:data) { |n| "data#{ n }" }
 	u.sequence(:user_agent) { |n| "user_agent#{ n }" }
 	u.sequence(:referrer) { |n| "referrer#{ n }" }
 	u.user_logged true
end