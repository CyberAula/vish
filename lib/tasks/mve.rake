
namespace :mve do

	task :mve => :environment do
		puts "Recalculating M(ost)V(aluable)E(xcursions) in all tables"
		# => This task recalculates MVE score in Excursions and Actors
		# => We use this MVE score to assign the Best Excursions of the Month and the Best Actors of the month
		# => Also is the task in charge of the ranking				
		
		recalculateMveExcursions
		rankMveExcursions
		recalculateMveAuthors
		rankMveAuthors
	
	end

	task :excludeBest => :environment do

	end

	def recalculateMveExcursions
		puts "Calculating Excursions MVE"
		biggest_mve = 0
		ident = 1
		for en in Excursion.all do
			followers = en.follower_count 
			visits = en.visit_count 
			likes = en.like_count
			comments = en.comment_count

			mve_count = ((followers * 5) + (visits * 5) + (comments * 5) + (likes * 10))
			
			#A different implementation of the algorithm to influence the time, and give dynamism, finally doing differently
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

		best_excursion = Excursion.find(ident)
		best_excursion.update_column :is_mve, true

		puts "The best excursion is number " + best_excursion.id.to_s
		puts " "
	end

	def rankMveExcursions
		puts "Generating MVE Rank in excursions"
		
		rank_counter = 1
		@mveRank = Excursion.all
		
		while (@mveRank.length != 0) do
			ranking_excursion = Excursion.find(@mveRank.max_by(&:mve).id)
			ranking_excursion.update_column :rankMve, rank_counter
			@mveRank.delete(@mveRank.max_by(&:mve))
			rank_counter+=1
		end
		
		puts "Ranking complete"
		puts " "
	end

	def recalculateMveAuthors
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

		best_actor = Actor.find(bestactorid)
		best_actor.update_column :is_mve, true

		puts "The best Actor is " + best_actor.name
		puts " "
	end

	def rankMveAuthors
		puts "Generating MVE Rank in Actors"
		
		rank_counter = 1
		@mveRank = Actor.all
		
		while (@mveRank.length != 0)
			ranking_actor = Actor.find(@mveRank.max_by(&:mve).id) #find looks for primary key
			ranking_actor.update_column :rankMve, rank_counter
			@mveRank.delete(@mveRank.max_by(&:mve))
			rank_counter+=1
		end
		puts "Ranking complete"
	end

end
