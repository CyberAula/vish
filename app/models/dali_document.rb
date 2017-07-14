class DaliDocument < ActiveRecord::Base
  # attr_accessible :title, :body
  include SocialStream::Models::Object
  belongs_to :owner, class_name: "Actor"
  define_index do
    activity_object_index
  end
  has_many :dali_exercises

  def absolutePath
    Vish::Application.config.full_domain + relativePath
  end

  def relativePath
    "/dali_documents/" + self.id.to_s + "/edit"
  end
end
