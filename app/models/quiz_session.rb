class QuizSession < ActiveRecord::Base
  belongs_to :owner, :class_name => 'Actor'
  has_many :quiz_answers, :dependent => :destroy
  
  scope :authored_by, lambda { |subject|
    QuizSession.where(:owner_id => Actor.normalize_id(subject))
  }

  scope :owned_by, lambda { |subject|
    QuizSession.authored_by(subject)
  }

  acts_as_xlsx

  def quizJSON(options=nil)
    self.quiz
  end

  def results
    self.quiz_answers
  end

  def self.root_url
    return Vish::Application.config.full_domain + "/quiz_sessions/"
  end

  def close_url
    return QuizSession.root_url + self.id.to_s() + "/close/"
  end

  def delete_url
    return QuizSession.root_url + self.id.to_s() + "/delete/"
  end

  def answer_url
    return Vish::Application.config.full_domain + "/qs/" + self.id.to_s()
  end

  def results_url
    return QuizSession.root_url + self.id.to_s() + "/results/"
  end

  def getProcessedQS
    begin
      qparams = self.getQuizParams
      qparams["processedResults"] = [];

      case qparams["quizType"]

        when "multiplechoice"
          qparams["totalAnswers"] = self.results.length

          qparams["choices"].each do |choice|
            choiceResult = Hash.new
            choiceResult["n"] = 0;
            qparams["processedResults"].push(choiceResult)
          end

          self.results.each do |result|
            result = JSON(result["answer"])

            #Result is an array of responses
            result.each do |response|
              if response["answer"]=="true"
                qparams["processedResults"][response["choiceId"].to_i-1]["n"] = qparams["processedResults"][response["choiceId"].to_i-1]["n"].to_i + 1
              end
            end
          end

          if qparams["totalAnswers"] > 0
            if qparams["extras"] && qparams["extras"]["multipleAnswer"]==true
              #Multiple choice with multiple answers
            else
              #Multiple choice with single answer
              #Calculate percentage
              qparams["processedResults"].each do |result|
                result["percentage"] = ((result["n"]*100)/qparams["totalAnswers"])
              end
            end
          end
          
        when "truefalse"

          qparams["choices"].each do |choice|
            choiceResult = Hash.new
            choiceResult["T"] = 0;
            choiceResult["F"] = 0;
            choiceResult["Tpercentage"] = 0;
            choiceResult["Fpercentage"] = 0;
            qparams["processedResults"].push(choiceResult)
          end

          self.results.each do |result|
            result = JSON(result["answer"])
            #Result is an array of responses
            result.each do |response|
              if response["answer"]=="true"
                qparams["processedResults"][response["choiceId"].to_i-1]["T"] = qparams["processedResults"][response["choiceId"].to_i-1]["T"].to_i + 1
              elsif response["answer"]=="false"
                qparams["processedResults"][response["choiceId"].to_i-1]["F"] = qparams["processedResults"][response["choiceId"].to_i-1]["F"].to_i + 1
              end
            end
          end

          #Calculate percentages
          qparams["processedResults"].each do |choiceResult|
            total = choiceResult["T"]+choiceResult["F"];
            if total > 0
              choiceResult["Tpercentage"] = (choiceResult["T"]*100)/(total);
              choiceResult["Fpercentage"] = (choiceResult["F"]*100)/(total);
            else
              choiceResult["Tpercentage"] = 0;
              choiceResult["Fpercentage"] = 0;
            end
          end

        when "sorting"
          qparams["totalAnswers"] = self.results.length

          qparams["processedResults"][0] = 0 #True responses
          qparams["processedResults"][1] = 0 #False responses
          qparams["processedResults"][2] = 0 #True percentage
          qparams["processedResults"][3] = 0 #False percentage

          self.results.each do |result|
            result = JSON(result["answer"])

            #Result is an array of responses
            result.each do |response|
              if !response["selfAssessment"].nil?
                if response["selfAssessment"]["result"]==true
                  qparams["processedResults"][0] = qparams["processedResults"][0].to_i + 1
                elsif response["selfAssessment"]["result"]==false
                  qparams["processedResults"][1] = qparams["processedResults"][1].to_i + 1
                end
              end
            end
          end

          if qparams["totalAnswers"] > 0
            #Calculate percentage
            qparams["processedResults"][2] = ((qparams["processedResults"][0]*100)/qparams["totalAnswers"])
            qparams["processedResults"][3] = ((qparams["processedResults"][1]*100)/qparams["totalAnswers"])
          end

        when "openAnswer"
          #Do nothing
        else
          # Unrecognized quiz type
      end

      return qparams

    rescue
      return Hash.new
    end
  end

  def getQuizParams
    qparams = Hash.new
    presentation = JSON(self.quizJSON)
    qparams["presentationName"] = presentation["title"]
    slide = presentation["slides"][0]
    els = slide["elements"]
    els.each do |el|
      if el["type"]=="quiz"
        #quiz founded
        qparams["question"] = el["question"]["value"];
        qparams["quizType"] = el["quiztype"];
        if el["choices"]
          qparams["nAnswers"] = el["choices"].length;
          qparams["choices"] = el["choices"];
        end
        if el["answer"]
          qparams["answer"] = el["answer"];
        end
        if el["extras"]
          qparams["extras"] = el["extras"];
        end
        return qparams
      end
    end
  end

end
