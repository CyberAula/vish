class EdiphyExercise < ActiveRecord::Base
  belongs_to :ediphy_document


  def absolutePath
    Vish::Application.config.full_domain + relativePath
  end

  def relativePath
    "/ediphy_exercises/" + self.id.to_s
  end
end
