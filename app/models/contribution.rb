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

  #Children
  has_many   :contributions, :foreign_key => 'parent_id'
  #Parent is managed by the 'parent' method. A parent can be a Workshop or another Contribution
  
  after_destroy :destroy_children_contributions


  validate :has_valid_ao
  def has_valid_ao
    if self.activity_object.nil?
      errors[:base] << "Invalid activity object"
    else
      true
    end
  end

  validate :has_valid_parent
  def has_valid_parent
    if self.parent.nil? or self.parent==self or self.all_contributions.include? self.parent or (!workshop_parent.nil? and !self.parent_id.nil?)
      errors[:base] << "Invalid parent"
    else
      true
    end
  end

  validate :is_valid_child
  def is_valid_child
    if !workshop_parent.nil? and workshop_parent.contributions.map{|c| c.activity_object}.include? self.activity_object
      #Duplicated child
      errors[:base] << "Invalid child"
    else
      true
    end
  end


  #Methods
  def parent
    workshop_parent || Contribution.find_by_id(self.parent_id)
  end

  def workshop_parent
    self.wa_assignment.workshop_activity.workshop unless self.wa_assignment.nil?
  end

  def all_contributions
    all_contributions = []
    direct_contributions = contributions
    all_contributions += direct_contributions

    direct_contributions.each do |dcontribution|
      all_contributions += dcontribution.all_contributions
    end

    all_contributions
  end

  def parents_path(path=nil)
    path ||= [self]
    cp = self.parent

    unless cp.nil?
      path.unshift(cp)
      if cp.class.name=="Contribution"
        return cp.parents_path(path)
      end
    end

    return path
  end

  def workshop
    cp = self.parent

    unless cp.nil?
      if cp.class.name == "Workshop"
        return cp
      elsif cp.respond_to? :workshop
        cp.workshop
      end
    end
  end

  def available_contributions_array(children=nil)
    if !self.wa_assignment.nil?
      self.wa_assignment.available_contributions_array
    elsif !self.parent.nil? and self.parent.respond_to? :available_contributions_array
      ac = self.parent.available_contributions_array(self)
      if ac.nil? and children.nil?
        #Contribution without root assignment
        custom_available_contributions_array
      else
        ac
      end
    else
      if children.nil?
        custom_available_contributions_array
      else
        nil
      end
    end
  end

  def custom_available_contributions_array
    object = self.activity_object.object
    unless object.nil?
      ([object.class.name, object.class.superclass.name] & VishConfig.getAvailableContributionTypes())
    else
      []
    end
  end

  def title
    self.activity_object.title
  end


  private

  def destroy_children_contributions
    self.contributions.each do |contribution|
      contribution.destroy
    end
  end

end
