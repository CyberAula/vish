class PrivateStudentGroup < ActiveRecord::Base
  belongs_to :private_teacher, foreign_key: "owner_id", class_name: "Actor"
  has_many :private_students, class_name: "User"
end