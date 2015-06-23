class Writing < ActiveRecord::Base
  include SocialStream::Models::Object

  define_index do
    activity_object_index

    #indexes plaintext
  end

  validates :title, :presence => true

  def as_json(options = nil)
    {:id => id,
     :title => title,
     :author => author.name,
     :fulltext => fulltext,
     :plaintext => plaintext
    }
  end
end
