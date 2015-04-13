include ActionDispatch::TestProcess

Factory.define :spamReport do |u|
	u.sequence(:issue) { |n| "Things that happen#{ n }" }
 	u.reporter_actor_id {|author| author.association(:user_vish, :name => 't3st1ng_d3m0_n4m3').actor }
 	u.report_value 1
 	u.activity_object { |ao| ao.association(:excursion).activity_object }
end