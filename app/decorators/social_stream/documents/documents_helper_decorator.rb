DocumentsHelper.module_eval do

  # Return the right icon of the resource
  def icon document, allowRaw=true
    #Default icons
    unless document.class.superclass.name != "Document"
      #For documents (based on SS documents)
      icon_name = case icon_mime_type document
        when :default then "file"
        when :text then "file-text"
        when :image then "image"
        when :audio then "music"
        when :video then "film"
        when :pdf then "file-pdf"
        when :swf then "file-swf"
        when :zip then "file-archive-o"
        when :doc then "file-word-o"
        when :odt then "file-word-o"
        when :ods then "file-excel-o"
        when :ppt then "file-powerpoint-o"
        when :odp then "file-powerpoint-o"
        else "file" #icon_mime_type document
      end
    else
      #For new ViSH models
      icon_name = case document.class.name
        when "Link" then "link"
        when "Embed" then "code"
        when "Writing" then "file-text"
        when "Scormfile" then "scorm"
        when "Imscpfile" then "scorm"
        when "Webapp" then "webapp"
        when "Workshop" then "book"
        when "Excursion" then "webapp"
        else "file" # SocialStream::Documents.icon_mime_types[:default]
      end
    end

    #Custom Avatars
    unless allowRaw==false
      customAvatar = document.getAvatarUrl
    else
      customAvatar = nil
    end

    unless customAvatar.nil?
      return "<div class='img-box resource_avatar resource_avatar_for_#{ icon_name }' style='background-image: url("+customAvatar+")'></div>"
    else
      return "<i class=\"fa fa-#{ icon_name }\"></i>".html_safe
    end
  end

  # Find the right class for the icon of this document, based on its format
  def icon_mime_type document
    if SocialStream::Documents.icon_mime_types[:subtypes].include?(document.format)
      document.format
    elsif SocialStream::Documents.icon_mime_types[:types].include?(document.mime_type_type_sym)
      document.mime_type_type_sym
    else
      "file" # SocialStream::Documents.icon_mime_types[:default]
    end
  end


end
