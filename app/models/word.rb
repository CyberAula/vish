class Word < ActiveRecord::Base
  validates :value, :presence => true, :uniqueness => true
  validates :occurrences, :presence => true, :numericality => { :greater_than => 0 }
end