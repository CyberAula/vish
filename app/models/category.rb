class Category < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :title
  #validates_uniqueness_of :title, :scope => :actor_id
  validate :title_not_duplicated

  private
  def title_not_duplicated
    errors.add(:base, "Title already exists") unless Category.all.map{ |category| category.id if(category.owner_id == self.owner_id && category.title == self.title) }.compact.blank?
  end
end