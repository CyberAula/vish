include ActionDispatch::TestProcess

Factory.define :waAssignment do |u|
	u.sequence(:fulltext) { |n| "name#{ n }" }
 	u.sequence(:plaintext) { |n| "desc#{ n }" }
 	u.workshop	{|wshop| wshop.association(:workshop) }
 	u.with_dates	false
 	u.report_value	rand(0..100)
 	u.pending	false
end#TODOWaAssignment(id: integer, fulltext: text, plaintext: text, with_dates: boolean, open_date: datetime, due_date: datetime, available_contributions: text, created_at: datetime, updated_at: datetime)
