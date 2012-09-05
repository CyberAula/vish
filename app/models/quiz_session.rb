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
  belongs_to :quiz
  belongs_to :owner, :class_name => 'User'
  has_many :quiz_answers
  has_one :excursion, :through => :quiz

  def answers
    ans_hash = QuizAnswer.group(:json).where(:quiz_session_id=>id).count
    ks = ans_hash.keys
    vs = ans_hash.values
    ks = ks.map do |k|
      j=JSON(k)
      j['option']
    end
    ans_hash=Hash[ks.zip(vs)]
    unless quiz.possible_answers_raw.empty?
      quiz.possible_answers_raw.each do |pa|
        ans_hash[pa]=0 if ans_hash[pa].nil?
      end
    end
    ans_hash
  end

  def answers_clear
    ans_hash = answers
    unless quiz.possible_answers.empty?
      ks = ans_hash.keys
      vs = ans_hash.values
      ks = ks.map do |k|
        quiz.possible_answers[k]
      end
      ans_hash=Hash[ks.zip(vs)]
    end
    ans_hash
  end
end
