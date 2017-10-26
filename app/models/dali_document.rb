class DaliDocument < ActiveRecord::Base
  # attr_accessible :title, :body
  include SocialStream::Models::Object
  belongs_to :owner, class_name: "Actor"
  define_index do
    activity_object_index
    has draft
  end
  after_save :parse_for_meta
  after_save :fix_post_activity_nil

  has_many :dali_exercises

  def absolutePath
    Vish::Application.config.full_domain + relativePath
  end

  def relativePath
    "/dali_documents/" + self.id.to_s + "/edit"
  end

  def thumbnail
    JSON.parse(self.json)["present"]["globalConfig"]["thumbnail"] || ""
  end


  private

   def parse_for_meta
      if self.draft
        activity_object.scope = 1
      else
        activity_object.scope = 0
      end
      activity_object.save!
   end
   
   def fix_post_activity_nil
    if self.post_activity == nil
      a = Activity.new :verb         => "post",
                       :author_id    => self.activity_object.author_id,
                       :user_author  => self.activity_object.user_author,
                       :owner        => self.activity_object.owner,
                       :relation_ids => self.activity_object.relation_ids,
                       :parent_id    => self.activity_object._activity_parent_id

      a.activity_objects << self.activity_object

      a.save!
    end
  end

end
