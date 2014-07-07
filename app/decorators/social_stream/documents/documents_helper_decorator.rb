DocumentsHelper.module_eval do

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

  # Return the right icon based on {#document}'s mime type
  def icon document, size=50
    icon_name = case icon_mime_type document
      when :default then "file"
      when :text then "file-text-o"
      when :image then "image"
      when :audio then "music"
      when :video then "file-video-o"
      when :pdf then "file-pdf-o"
      when :zip then "file-pdf-o"
      when :scorm then "cube"
      when :swf then "file-swf-o"

      else icon_mime_type document
    end
    if icon_name == "picture"
      "<div class='img-box' id='document-#{document.id}'></div><i class=\"fa fa-#{ icon_name }\"></i>".html_safe
    else
      "<i class=\"fa fa-#{ icon_name }\"></i>".html_safe
    end
  end

end
