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
 
####################
## Moodle Quiz XML Management
####################

require 'builder'

class MOODLEQUIZXML


  def self.generate_MoodleQUIZMC(qjson)
   #   myxml = ::Builder::XmlMarkup.new(:indent => 2)
   #   myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

   #   nChoices = qjson["choices"].size

   #   if qjson["extras"]["multipleAnswer"] == false 
   #         card = "true"
   #       else
   #         card = "false"
   #   end 

   #   myxml.quiz do
   #     myxml.question("type" => "category") do
   #       myxml.category do
   #         myxml.text do
   #            myxml.text!("Moodle QUIZ XML export")
   #         end
   #       end
   #     end

   #     myxml.question("type" => "multichoice") do
   #       myxml.name do
   #         myxml.text do
   #           myxml.text!(qjson["question"]["value"])
   #         end #end del text
   #       end #end del name
   #       for i in 0..((nChoices)-1)
   #         if qjson["choices"][i]["answer"] == true
   #           mappedV = "100"
   #         else
   #           mappedV = "0"
   #         end
   #           myxml.answer("fraction" => mappedV) do
   #             myxml.text(qjson["choices"][i]["value"])
   #           end
   #         end
   #         myxml.shuffleanswers("1")
   #         myxml.single(card)
   #     end #end del question
   #   end
   # end
   # return myxml;
end



  def self.generate_MoodleQUIZTF(qjson)
  #   myxml = ::Builder::XmlMarkup.new(:indent => 2)
  #   myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

  #   nChoices = qjson["choices"].size

  #   if qjson["extras"]["multipleAnswer"] == false 
  #         card = "true"
  #       else
  #         card = "false"
  #   end 

  #   myxml.quiz do
  #     myxml.question("type" => "category") do
  #       myxml.category do
  #         myxml.text do
  #            myxml.text!("Moodle QUIZ XML export")
  #         end
  #       end
  #     end

  #     myxml.question("type" => "multichoice") do
  #       myxml.name do
  #         myxml.text do
  #           myxml.text!(qjson["question"]["value"])
  #         end #end del text
  #       end #end del name
  #       for i in 0..((nChoices)-1)
  #         if qjson["choices"][i]["answer"] == true
  #           mappedV = "100"
  #         else
  #           mappedV = "0"
  #         end
  #           myxml.answer("fraction" => mappedV) do
  #             myxml.text(qjson["choices"][i]["value"])
  #           end
  #         end
  #         myxml.shuffleanswers("1")
  #         myxml.single(card)
  #     end #end del question
  #   end
  # end
  # return myxml;
  end

end