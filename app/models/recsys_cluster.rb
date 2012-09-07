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

class RecsysCluster < ActiveRecord::Base
  establish_connection "recsys_#{Rails.env}"
  set_table_name "clusters"
  set_primary_key "id"

  has_one :center, :class_name => 'RecsysUser', :foreign_key => 'centerid'
  has_many :objects, :class_name => 'RecsysLearningObject', :foreign_key => 'clusterid'
  has_many :users, :class_name => 'RecsysUser', :foreign_key => 'clusterid'

  def actors
    users.map{ |u| u.actor }
  end

  def activity_objects
    objects.map{ |o| o.activity_object }
  end

  def readonly?
    return true
  end
 
  # Prevent objects from being destroyed
  def before_destroy
    raise ActiveRecord::ReadOnlyRecord
  end

end
