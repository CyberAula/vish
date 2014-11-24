class Embed < ActiveRecord::Base
  include SocialStream::Models::Object

  define_index do
    activity_object_index

    has live
  end

  def as_json(options = nil)
    {:id => id,
     :title => title,
     :description => description,
     :author => author.name,
     :fulltext => fulltext
    }
  end
end
