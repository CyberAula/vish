class Category < ActiveRecord::Base
  include SocialStream::Models::Object

  validates_presence_of :title
  #Problem in categories controller
  validate :title_not_duplicated, on: :create

  define_index do
    activity_object_index
  end

  #Return the array with the order of the items of the category
  def categories_order
    order = self.category_order
    unless order.nil?
      begin
        order = JSON.parse(order).map{|pos| pos.to_i}
      rescue
        order = nil
      end
    end
    order
  end

  private
  def title_not_duplicated
    errors.add(:title, "duplicated") unless Category.all.map{ |category| category.id if(category.owner_id == self.owner_id && category.title == self.title) }.compact.blank?
  end
end