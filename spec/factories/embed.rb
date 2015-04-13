include ActionDispatch::TestProcess

Factory.define :embed do |u|
    u.sequence(:fulltext) { |n| "name#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
end