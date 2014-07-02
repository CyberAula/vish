ActivityObject.class_eval do

  #Calculate quality score (in a 0-10 scale) 
  def calculate_qscore
    #self.reviewers_qscore is the LORI score in a 0-10 scale
    #self.users_qscore is the WBLT-S score in a 0-10 scale
    qscoreWeights = {}
    qscoreWeights[:reviewers] = BigDecimal(0.6,6)
    qscoreWeights[:users] = BigDecimal(0.4,6)

    if self.reviewers_qscore.nil?
      #If nil, we consider it 0 in a [-5,5] scale.
      reviewerScore = BigDecimal(0.0,6)
    else
      reviewerScore = self.reviewers_qscore - 5
    end

    if self.users_qscore.nil?
      #If nil, we consider it 0 in a [-5,5] scale.
      usersScore = BigDecimal(0.0,6)
    else
      usersScore = self.users_qscore - 5
    end

    #overallQualityScore is in a  [-1,1] scale
    overallQualityScore = (qscoreWeights[:users] * usersScore + qscoreWeights[:reviewers] * reviewerScore)/5

    self.update_column :qscore, overallQualityScore
  end

end