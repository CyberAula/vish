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

  has_many :quizzes, :dependent => :destroy

  has_many :excursion_contributors, :dependent => :destroy
  has_many :contributors, :class_name => "Actor", :through => :excursion_contributors

  validates_presence_of :json
  after_save :parse_for_meta
  before_save :fix_relation_ids_drafts

  define_index do
    activity_object_index

    has slide_count
    has draft
    has activity_object.like_count, :as => :like_count
    has activity_object.visit_count, :as => :visit_count
  end

  def to_json(options=nil)
    json
  end

  def clone_for sbj
    return nil if sbj.blank?
    e=Excursion.new
    e.author=sbj
    e.owner=sbj
    e.user_author=sbj.user.actor
    e.json=self.quizless_json # We do this so quizzes are re-created upon cloning.
    e.contributors=self.contributors.push(self.author)
    e.contributors.uniq!
    e.contributors.delete(sbj)
    e.draft=true
    e.save!
    e
  end

  def has_quizzes?
    not quizzes.empty?
  end

  def has_quiz_results?
    has_quizzes? # TODO: Hide unless there are answers
  end

  def quizless_json
    parsed_json = JSON(json)
    parsed_json["slides"].each do |slide|
      slide.delete("quiz_id")
    end
    parsed_json.to_json
  end

  private

  def extract_quizzes(parsed_json)
    parsed_json["slides"].each do |slide|
      next unless slide["type"] == "quiz"
      next unless slide["template"] =~ /^t1[012]$/
      if slide["quiz_id"].nil?
        quiz = Quiz.new
      else
        quiz = Quiz.find(slide["quiz_id"])
      end
      quiz.excursion=self
      case slide["template"]
        when "t10" # Open question
          quiz.type="OpenQuiz"
          # PENDING
        when "t11" # Multiple-choice
          quiz.type="MultipleChoiceQuiz"
          qelem = slide["elements"].select { |e| e["type"] == "mcquestion" }.first
          quiz.question = qelem["question"] unless qelem.nil? or qelem["question"].nil?
          quiz.options  = qelem["options"].join(",") unless qelem.nil? or qelem["options"].nil?
        when "t12" # True/False
          quiz.type="TrueFalseQuiz"
          # PENDING
      end
      quiz.simple_json = slide["quiz_simple_json"].to_json
      quiz.save!
      slide["quiz_id"]=quiz.id
    end
    parsed_json
  end

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["title"]
    activity_object.description = parsed_json["description"]
    activity_object.tag_list = parsed_json["tags"]
    activity_object.save!

    parsed_json["id"] = activity_object.id.to_s
    parsed_json["author"] = author.name
    parsed_json = extract_quizzes(parsed_json) # Fill up quiz_id parameters
    self.update_column :json, parsed_json.to_json

    self.update_column :slide_count, parsed_json["slides"].size
    self.update_column :thumbnail_url, parsed_json["avatar"]

  end

  def fix_relation_ids_drafts
    if draft
      activity_object.relation_ids=[Relation::Private.instance.id]
    else
      activity_object.relation_ids=[Relation::Public.instance.id]
    end
  end

end
