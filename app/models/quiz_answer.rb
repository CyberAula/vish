class QuizAnswer < ActiveRecord::Base
  belongs_to :quiz_session

  def answerJSON(options=nil)
  	self.answer
  end

end