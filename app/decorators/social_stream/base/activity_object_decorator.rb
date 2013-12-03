ActivityObject.class_eval do
  include HomeHelper
  before_save :recalculate_popularity

  #method to recalculate the popularity of an object
  #depending on the type of object the algorithm will be different
  def recalculate_popularity
  	if object_type == "Actor"
  		#first calculate the popularity of his/her excursions
  		sum_popularity = 0
  		subject_excursions(self.actor.user,{:scope=> :me, :limit =>0}).each do |ex|
  			if ex.popularity
  				sum_popularity += ex.popularity
  			end
  		end
  		self.popularity = follower_count*50 + sum_popularity
  	else
  		self.popularity = visit_count + like_count*5 
  	end
  end

end