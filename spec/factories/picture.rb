Factory.define :picture do |u|
	u.sequence(:title) { |n| "name#{ n }" }
 	u.sequence(:description) { |n| "desc#{ n }" }
 	u.author {|author| author.association(:user_vish, :name => 'Writely') }
 	u.owner {|author| author.association(:user_vish, :name => 'Writely') }
 	u.file ["http://s0.geograph.org.uk/geophotos/01/74/36/1743675_513c1a7a.jpg"]
end