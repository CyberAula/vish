# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

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