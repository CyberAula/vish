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

class Excursion < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :json
  before_save :parse_for_meta

  define_index do
    activity_object_index
  end

  def to_json(options=nil)
    json
  end

  def thumb(size, helper)
    case size
      when 50 
        "logos/actor/excursion-#{sprintf '%.2i', thumbnail_index}.png"
      else
        "logos/original/excursion-#{sprintf '%.2i', thumbnail_index}.png"
    end
  end

  private

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["title"]
    activity_object.description = parsed_json["description"]
    activity_object.save!

    self.slide_count = parsed_json["slides"].size
  end

end
