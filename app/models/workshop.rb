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
require 'builder'

class Workshop < ActiveRecord::Base
  include SocialStream::Models::Object
  has_many :workshop_activities

  after_destroy :destroy_workshop_activities

  define_index do
    activity_object_index
    has draft
  end

  validates_inclusion_of :draft, :in => [true, false]

  def thumbnail_url
    self.getAvatarUrl || "/assets/logos/original/defaul_workshop.png"
  end

  def hasAssignments
    self.workshop_activities.select{|workshop_activity| workshop_activity.wa_type=="WaAssignment"}.length > 0
  end

  def contributions
    self.workshop_activities.select{|workshop_activity| workshop_activity.wa_type=="WaAssignment"}.map{|workshop_activity| workshop_activity.object.contributions}.flatten.uniq
  end


  private

  def destroy_workshop_activities
    self.workshop_activities.each do |wactivity|
      wactivity.destroy
    end
  end

end
