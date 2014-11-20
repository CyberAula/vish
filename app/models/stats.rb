class Stats < ActiveRecord::Base
  
  #increment this stat name in this value_to_increment
  #creates the stat if it does not exist
  def self.increment(name, value_to_increment)
  	the_stat = Stats.find_by_stat_name(name)
  	if !Stats.find_by_stat_name(name)
  		the_stat = Stats.new(:stat_name => name, :stat_value=>0)
  	end
  	
  	the_stat.stat_value += value_to_increment
  	the_stat.save
  end

end