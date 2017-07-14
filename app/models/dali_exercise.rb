class DaliExercise < ActiveRecord::Base
  belongs_to :dali_document


  def absolutePath
    Vish::Application.config.full_domain + relativePath
  end

  def relativePath
    "/dali_exercises/" + self.id.to_s
  end
end
