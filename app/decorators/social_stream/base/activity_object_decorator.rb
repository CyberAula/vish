ActivityObject.class_eval do

  before_save :fill_indexed_lengths

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

  def fill_indexed_lengths
    if self.title.is_a? String and self.title.scan(/\w+/).size>0
      self.title_length = self.title.scan(/\w+/).size
    end
    if self.description.is_a? String and self.description.scan(/\w+/).size>0
      self.desc_length = self.description.scan(/\w+/).size
    end
    if self.tag_list.is_a? ActsAsTaggableOn::TagList and self.tag_list.length>0
      self.tags_length = self.tag_list.length
    end
  end

end