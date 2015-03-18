Factory.define :excursion do |exc|
	exc.sequence(:title) { |n| "Kik #{ n }" }
	exc.author {|author| author.association(:user_vish, :name => 'Writely') }
	exc.owner {|author| author.association(:user_vish, :name => 'Writely') }
	exc.params{{}}
end