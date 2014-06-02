
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

	#Task to fill with best into the excluded table
	task :excludeBest => :environment do
		puts "Introducing into exclusion list best excursions"

		bestExcursion = Excursion.where(is_mve: true)
		if ExcludeExcMve.where(id: bestExcursion[0].id).length == 0
			exc = ExcludeExcMve.new :id => bestExcursion[0].id, :excName=> bestExcursion[0].title ,:rankTime =>0 
			exc.save
			puts "Excursion " + bestExcursion[0].title + " excluded"
		end
		puts "Introducing into exclusion list best author"

		bestAuthor = Actor.where(is_mve: true)
		if ExcludeAuthMve.where(id: bestAuthor[0].id).length == 0
			au = ExcludeAuthMve.new :id => bestAuthor[0].id, :authName=> bestAuthor[0].name, :rankTime =>0 
			au.save
			puts "Author " + bestAuthor[0].title + " excluded"
		end

		for excExc in ExcludeExcMve.all do
			rank = excExc.rankTime + 1 
			excExc.update_column :rankTime, rank
		end
		for excAuth in ExcludeAuthMve.all do
			rank= excAuth.rankTime + 1
			excAuth.update_column :rankTime, rank
		end

		ExcludeAuthMve.where(rankTime: 10).destroy_all
		ExcludeExcMve.where(rankTime: 10).destroy_all

	end

	#This is the main Task. Used in cron to keep ranking the way, that has to be.
	task :Rank => :environment do
		Rake::Task["mve:mve"].invoke
		Rake::Task["mve:excludeBest"].invoke
	end

	#Task to clean excluded tables
	task :cleanExcluded => :environment do
		puts "Cleaned Excursions: " + ExcludeExcMve.delete_all.to_s
		puts "Cleaned Authors: " + ExcludeAuthMve.delete_all.to_s
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
		
		id_toCheck = 0
		check = true
		@mveRank = Excursion.all

		while check do		
			id_toCheck = Excursion.find(@mveRank.max_by(&:mve)).id

			if ExcludeExcMve.where(id: id_toCheck).length == 1
				@mveRank.delete(@mveRank.max_by(&:mve))
			else
				Excursion.find(id_toCheck).update_column :is_mve, true
				check=false
			end
	    end
		
		puts "The best excursion is number " + id_toCheck.to_s
		puts " "

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

		id_toCheck = 0
		check = true
		@mveRank = Actor.all
		while check do		
			id_toCheck = Actor.find(@mveRank.max_by(&:mve)).id
			if ExcludeAuthMve.where(id: id_toCheck).length == 1
				@mveRank.delete(@mveRank.max_by(&:mve))
			else
				Actor.find(id_toCheck).update_column :is_mve, true
				check=false
			end
	    end

		puts "Ranking complete"
	end

end
