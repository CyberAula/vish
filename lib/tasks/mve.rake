
namespace :mve do

	task :mve => :environment do
		puts "Recalculating M(ost)V(aluable)E(xcursions) in all tables"
		#
		#
		#
		#
		puts "Calculating Excursions MVE"
		#Cálculo Mve in Excursion
		biggest_mve = 0
		ident = 1
		for en in Excursion.all do
			followers = en.follower_count 
			visits = en.visit_count 
			likes = en.like_count
			comments = en.comment_count

			mve_count = ((followers * 5) + (visits * 5) + (comments * 5) + (likes * 10))
			
			#Add this lines instead if want to include time influence
			#threshold = 100
			#created =  (DateTime.now.to_i - DateTime.parse(en.created_at.to_s).to_i)/threshold 
			#updated = (DateTime.now.to_i - DateTime.parse(en.updated_at.to_s).to_i)/threshold 
			#timing_things = updated - created
			#mve_count = ((followers * 5) + (visits * 5) + (comments * 5) + (likes * 10))/timing_things
			
			
			if(mve_count > biggest_mve)
				biggest_mve = mve_count
				ident = en.id
			end

			en.update_column :mve, mve_count
			en.update_column :is_mve, false
		end

		best_excursion = Excursion.find( id = ident)
		best_excursion.update_column :is_mve, true

		puts "The best excursion is number " + id.to_s
		puts " "
		puts "Calculating Authors MVE"

		#Clean Authors MVE
		for aut in Actor.all do
			aut.update_column :mve, 0
			aut.update_column :is_mve, false
		end

		#Update Authors MVE
		for exc in Excursion.all do
			author = exc.author
			author_mve = author.mve + exc.mve
			author.update_column :mve, author_mve

		end

		bestactorid = 1
		bestmve = 0
		#Get the MVE
		for searchMVE in Actor.all do 
			if (searchMVE.mve > bestmve)
				bestmve = searchMVE.mve
				bestactorid = searchMVE.id				
			end
		end

		best_actor = Actor.find( id = bestactorid)
		best_actor.update_column :is_mve, true

		puts "The best Actor is " + best_actor.name
	end

end
