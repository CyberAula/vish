module RepositoryHelper

  def icon_class_for(document)
    return 'icon-unknown' unless document.respond_to? :type
    return 'icon-document' if document.type.nil?
    "icon-#{document.type.downcase}"
  end

end
