class Category < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :title
  validate :title_not_duplicated

  define_index do
    activity_object_index
  end

  private
  def title_not_duplicated
    errors.add(:title, "duplicated") unless Category.all.map{ |category| category.id if(category.owner_id == self.owner_id && category.title == self.title) }.compact.blank?
  end
end