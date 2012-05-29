module RepositoryHelper

  def icon_class_for(document)
    return 'icon_x-link' if document.is_a? Link
    return 'iconx-default' unless document.respond_to? :type
    return 'iconx-default' if document.type.nil?
    "iconx-#{document.type.downcase}"
  end

  def icon75_class_for(document)
    return 'icon_75-link' if document.is_a? Link
    return 'icon75-default' unless document.respond_to? :type
    return 'icon75-default' if document.type.nil?
    "icon75-#{document.type.downcase}"
  end

end
