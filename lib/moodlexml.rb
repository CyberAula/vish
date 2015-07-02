####################
## Moodle Quiz XML Management
####################

require 'builder'

class MOODLEQUIZXML

  def self.createMoodleQUIZXML(filePath,fileName,qjson)

    t = File.open("#{filePath}#{fileName}.xml", 'w') do |zos|

      case qjson["quiztype"]

      when "multiplechoice"
        moodlequizmc = MOODLEQUIZXML.generate_MoodleQUIZMC(qjson)
        #zos.put_next_entry(fileName + ".xml")
        #Zero-width space <200b> erased from target in moodlequizmc
        zos.print moodlequizmc.target!().gsub("\u{200B}","" )

      when "openAnswer"
        if qjson["selfA"] == true
          moodlequizoa = MOODLEQUIZXML.generate_MoodleQUIZSA(qjson)
        else
          moodlequizoa = MOODLEQUIZXML.generate_MoodleQUIZLA(qjson)
        end
         # zos.put_next_entry(fileName + ".xml")
          zos.print moodlequizoa.target!().gsub("\u{200B}","" )

      when "sorting"
        moodlequizs = MOODLEQUIZXML.generate_MoodleQUIZSorting(qjson)
        #zos.put_next_entry(fileName + ".xml")
        zos.print moodlequizs.target!().gsub("\u{200B}","" )

      when "truefalse"
        moodlequiztf = MOODLEQUIZXML.generate_MoodleQUIZTF(qjson)
        #zos.put_next_entry(fileName + ".xml")
        zos.print moodlequiztf.target!().gsub("\u{200B}","" )

      else
      end

    end

  end


  def self.generate_MoodleQUIZMC(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    nChoices = qjson["choices"].size
    question_t = (qjson["question"]["value"]).to_s.lstrip rescue ""
    settings = qjson["settings"] || {}
    shuffleAnswers = settings["shuffleChoices"]

    if qjson["extras"]["multipleAnswer"] == false 
      card = "true"
    else
      card = "false"
    end

    myxml.quiz do  
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text("Moodle QUIZ XML export")
        end
      end

      myxml.question("type" => "multichoice") do
        myxml.name do
          myxml.text(question_t)
        end
        myxml.questiontext do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        if shuffleAnswers == true
          myxml.shuffleanswers("1")
        else 
          myxml.shuffleanswers("0")
        end
        
        myxml.single(card)

        for i in 0..((nChoices)-1)
          if qjson["choices"][i]["answer"] == true
            mappedV = "100"
          else
            mappedV = "0"
          end
          myxml.answer("fraction" => mappedV) do
            myxml.text(((qjson["choices"][i]["value"]).to_s).lstrip)
          end
        end

      end
    end

    return myxml;
  end


  def self.generate_MoodleQUIZTF(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    nChoices = qjson["choices"].size

    myxml.quiz do
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text("Moodle QUIZ XML export")
        end
      end

      for i in 0..((nChoices)-1)
        myxml.question("type" => "truefalse") do

          myxml.name do
            myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
          end

          myxml.questiontext do
            myxml.text(((qjson["choices"][i]["value"]).to_s).lstrip)  
          end

          if(qjson["choices"][i]["answer"] == true)
            mappedVT = "100"
            mappedVF = "0"
          else 
            mappedVT = "0"
            mappedVF = "100"
          end
             
          myxml.answer("fraction" => mappedVT) do
            myxml.text("true")
          end

          myxml.answer("fraction" => mappedVF) do
            myxml.text("false")
          end 

        end
      end
    end

    return myxml;
  end


  def self.generate_MoodleQUIZSA(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    myxml.quiz do  
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text("Moodle QUIZ XML export")
        end
      end

      myxml.question("type" => "shortanswer") do
        myxml.name do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.questiontext do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.answer("fraction" => "100") do
            myxml.text(((qjson["answer"]["value"]).to_s).lstrip)
          end
      end
    end

    return myxml;
  end


  def self.generate_MoodleQUIZLA(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"

    myxml.quiz do  
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text("Moodle QUIZ XML export")
        end
      end

      myxml.question("type" => "essay") do
        myxml.name do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.questiontext do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.answer("fraction" => "0") do
            myxml.text
          end
      end
    end

    return myxml;
  end


  def self.generate_MoodleQUIZSorting(qjson)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    
    nChoices = qjson["choices"].size

    myxml.quiz do  
      myxml.question("type" => "category") do
        myxml.category do
          myxml.text("Moodle QUIZ XML export")
        end
      end

      myxml.question("type" => "matching") do
        myxml.name do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.questiontext do
          myxml.text(((qjson["question"]["value"]).to_s).lstrip)  
        end
        myxml.shuffleanswers("false")

        for i in 0..((nChoices)-1)
          myxml.subquestion do
            myxml.text((i+1).to_s)
            myxml.answer do
              myxml.text(((qjson["choices"][i]["value"]).to_s).lstrip)
            end
          end
        end
      end
    end
    
    return myxml;
  end

end