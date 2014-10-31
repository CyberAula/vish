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

class Contribution < ActiveRecord::Base
  belongs_to :activity_object
  belongs_to :wa_assignment

  #belongs_to  :parent, :class_name => 'Contribution'
  #has_many 	:children, :class_name => 'Contribution', :foreign_key => 'parent_id'
  	
  def workshop
    return workshop_parent unless workshop_parent.nil?

    contribution = Contribution.find_by_id(self.parent_id)
    contribution.workshop unless contribution.nil?
  end

  def workshop_parent
    self.wa_assignment.workshop_activity.workshop unless self.wa_assignment.nil?
  end

  def parent
    workshop_parent || Contribution.find_by_id(self.parent_id)
  end

  def parents_path(path=nil)
    path ||= [self]
    wp = self.parent

    unless wp.nil?
      path.unshift(wp)
      if wp.class.name=="Contribution"
        return wp.parents_path(path)
      end
    end

    return path
  end

  def title
    self.activity_object.title
  end

end
