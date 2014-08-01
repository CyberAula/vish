DocumentsHelper.module_eval do

  # Return the right icon based on {#document}'s mime type
  def icon document, size=50
    unless document.class.superclass.name != "Document"
      icon_name = case icon_mime_type document
        when :default then "file"
        when :text then "file-text"
        when :image then "picture"
        when :audio then "music"
        when :video then "film"
        when :pdf then "pdf-new"
        when :zip then "zip-new"
        when :scorm then "scorm-new"
        when :swf then "swf-new"
        else icon_mime_type document
      end
    else
      icon_name = case document.class.name
        when "Link" then "link"
        when "Embed" then "code"
        when "Scormfile" then "scorm-new"
        when "Webapp" then "webapp-new"
        else SocialStream::Documents.icon_mime_types[:default]
      end
    end

    if icon_name == "picture"
      "<div class='img-box' id='document-#{document.id}'></div><i class=\"icon-#{ icon_name }\"></i>".html_safe
    else
      "<i class=\"icon-#{ icon_name }\"></i>".html_safe
    end
  end

  # Find the right class for the icon of this document, based on its format
  def icon_mime_type document
    if SocialStream::Documents.icon_mime_types[:subtypes].include?(document.format)
      document.format
    elsif SocialStream::Documents.icon_mime_types[:types].include?(document.mime_type_type_sym)
      document.mime_type_type_sym
    else
      SocialStream::Documents.icon_mime_types[:default]
    end
  end

end
