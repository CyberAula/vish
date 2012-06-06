module RepositoryHelper

  def icon_class_for(document)
    return 'icon_x-link' if document.is_a? Link
    return 'iconx-default' unless document.respond_to? :type
    case document.file.url.to_s.downcase[-3,3]
    when "pdf"
      return 'iconx-pdf'
    else
      return 'iconx-default'
    end
  end

  def icon75_class_for(document)
    return 'icon_75-link' if document.is_a? Link
    return 'icon75-default' unless document.respond_to? :type
    case document.file.url.to_s.downcase[-3,3]
    when "pdf"
      return 'icon75-pdf'
    else
      return 'icon75-default'
    end
  end

end
