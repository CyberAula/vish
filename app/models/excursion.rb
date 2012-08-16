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

  has_many :quizzes

  validates_presence_of :json
  before_save :parse_for_meta

  define_index do
    activity_object_index
  end

  def to_json(options=nil)
    json
  end

  def extract_quizzes(parsed_json)
    parsed_json["slides"].each do |s|
      next unless s["template"] =~ /^t1[012]$/
      next unless s["quiz_id"].nil?
      q = Quiz.new
      q.excursion=self
      case s["template"]
        when "t10" # Open question
          q.type="OpenQuiz"
          # PENDING
        when "t11" # Multiple-choice
          q.type="MultipleChoiceQuiz"
          qelem = s["elements"].select { |e| e["type"] == "mcquestion" }.first
          q.question = qelem["question"] unless qelem.nil? or qelem["question"].nil?
          q.options  = qelem["options"].join(",") unless qelem.nil? or qelem["options"].nil?
        when "t12" # True/False
          q.type="TrueFalseQuiz"
          # PENDING
      end
      q.save!
      s["quiz_id"]=q.id
    end
    parsed_json
  end

  private

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["title"]
    activity_object.description = parsed_json["description"]
    activity_object.save!

    parsed_json["id"] = activity_object.id
    parsed_json["author"] = author.name
    parsed_json = extract_quizzes(parsed_json) # Fill up quiz_id parameters
    self.json = parsed_json.to_json

    self.slide_count = parsed_json["slides"].size
    self.thumbnail_url = parsed_json["avatar"]

  end

end
