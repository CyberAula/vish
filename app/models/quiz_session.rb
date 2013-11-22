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

class QuizSession < ActiveRecord::Base
  belongs_to :owner, :class_name => 'User'
  has_many :quiz_answers, :dependent => :destroy

  def quizJSON(options=nil)
  	self.quiz
  end

  def results
  	self.quiz_answers
  end

  def getQuizParams
    qparams = Hash.new
    qparams["quiz"] = self.quizJSON

    begin
      presentation = JSON(self.quizJSON)
      qparams["presentationName"] = presentation["title"]
      slide = presentation["slides"][0]
      els = slide["elements"]
      els.each do |el|
        if el["type"]=="quiz"
          #quiz founded
          qparams["question"] = el["question"]["value"];
          qparams["quizType"] = el["quizType"];
          qparams["nAnswers"] = el["choices"].length;
          qparams["choices"] = el["choices"];
          return qparams
        end
      end
    rescue
      #empty params
      return qparams
    end
  end

  def self.root_url
    if Site.current.config[:documents_hostname]
      return Site.current.config[:documents_hostname].to_s + "quiz_sessions/"
    end
  end

  def close_url
    return QuizSession.root_url + self.id.to_s() + "/close/"
  end

  def delete_url
    return QuizSession.root_url + self.id.to_s() + "/delete/"
  end

  def answer_url
    if Site.current.config[:documents_hostname]
      return Site.current.config[:documents_hostname].to_s + "qs/" + self.id.to_s()
    end
  end

  def results_url
    return QuizSession.root_url + self.id.to_s() + "/results/"
  end

end
