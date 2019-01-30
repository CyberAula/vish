class EdiphyDocumentContributor < ActiveRecord::Base
  belongs_to :ediphy_document
  belongs_to :contributor, :class_name => "Actor"
end

