module RepositoryHelper

  def icon_class_for(document)
    return 'iconx-default' unless document.respond_to? :type
    return 'iconx-default' if document.type.nil?
    "iconx-#{document.type.downcase}"
  end

end
