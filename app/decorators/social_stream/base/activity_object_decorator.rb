ActivityObject.class_eval do

  #Calculate quality score (in a 0-10 scale) 
  def calculate_qscore
    #self.reviewers_qscore is the LORI score in a 0-10 scale
    #self.users_qscore is the WBLT-S score in a 0-10 scale
    qscoreWeights = {}
    qscoreWeights[:reviewers] = BigDecimal(0.9,6)
    qscoreWeights[:users] = BigDecimal(0.1,6)

    if self.reviewers_qscore.nil?
      #If nil, we consider it 5 in a [0,10] scale.
      reviewerScore = BigDecimal(5.0,6)
    else
      reviewerScore = self.reviewers_qscore
    end

    if self.users_qscore.nil?
      #If nil, we consider it 5 in a [0,10] scale.
      usersScore = BigDecimal(5.0,6)
    else
      usersScore = self.users_qscore
    end

    #overallQualityScore is in a  [0,10] scale
    overallQualityScore = (qscoreWeights[:users] * usersScore + qscoreWeights[:reviewers] * reviewerScore)

    #Translate it to a scale of [0,1000000]
    overallQualityScore = overallQualityScore * 100000

    self.update_column :qscore, overallQualityScore
  end

end