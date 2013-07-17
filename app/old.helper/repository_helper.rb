module RepositoryHelper

  def icon_class_for(document)
    return 'icon_repository32-32_link' if document.is_a? Link
    return 'icon_repository32-32_embed' if document.is_a? Embed
    case document.file.url.to_s.split('.').last.downcase
        
    when "embed"
      return 'icon_repository32-32_embed'
    when "pdf"
      return 'icon_repository32-32_pdf'
    when "mathml"  
      return 'icon_repository32-32_mathml'
    when "txt"  
      return 'icon_repository32-32_txt'      
    when "doc"  
      return 'icon_repository32-32_word'
    when "docx"  
      return 'icon_repository32-32_word'      
    when "ppt"  
      return 'icon_repository32-32_ppt'
    when "pptx"  
      return 'icon_repository32-32_ppt'      
    when "xls"  
      return 'icon_repository32-32_excel'      
    when "audio"  
      return 'icon_repository32-32_audio'      
    when "mp3"  
      return 'icon_repository32-32_mp3'      
    when "wav"  
      return 'icon_repository32-32_wav'      
    when "picture"  
      return 'icon_repository32-32_picture'      
    when "tiff"  
      return 'icon_repository32-32_tiff'      
    when "jpg"  
      return 'icon_repository32-32_jpg'      
    when "gif"  
      return 'icon_repository32-32_gif'      
    when "svg"  
      return 'icon_repository32-32_svg'      
    when "zip"  
      return 'icon_repository32-32_zip'      
    when "rar"  
      return 'icon_repository32-32_rar'      
    when "avi"  
      return 'icon_repository32-32_avi'      
    when "mp4"  
      return 'icon_repository32-32_mp4'      
    when "mov"  
      return 'icon_repository32-32_mov'      
    when "swf"  
      return 'icon_repository32-32_flash'      
    else
      return 'icon_repository32-32_file'
    end
  end

  def icon75_class_for(document)
    return 'icon_repository75-75_link' if document.is_a? Link
    return 'icon_repository75-75_embed' if document.is_a? Embed
    case document.file.url.to_s.split('.').last.downcase
    when "embed"
      return 'icon_repository75-75_embed'
    when "pdf"
      return 'icon_repository75-75_pdf'
    when "mathml"  
      return 'icon_repository75-75_mathml'
    when "txt"  
      return 'icon_repository75-75_txt'      
    when "doc"  
      return 'icon_repository75-75_word'
    when "docx"  
      return 'icon_repository75-75_word'      
    when "ppt"  
      return 'icon_repository75-75_ppt'
    when "pptx"  
      return 'icon_repository75-75_ppt'      
    when "xls"  
      return 'icon_repository75-75_excel'      
    when "audio"  
      return 'icon_repository75-75_audio'      
    when "mp3"  
      return 'icon_repository75-75_mp3'      
    when "wav"  
      return 'icon_repository75-75_wav'      
    when "picture"  
      return 'icon_repository75-75_picture'      
    when "tiff"  
      return 'icon_repository75-75_tiff'      
    when "jpg"  
      return 'icon_repository75-75_jpg'      
    when "gif"  
      return 'icon_repository75-75_gif'      
    when "svg"  
      return 'icon_repository75-75_svg'      
    when "zip"  
      return 'icon_repository75-75_zip'      
    when "rar"  
      return 'icon_repository75-75_rar'      
    when "avi"  
      return 'icon_repository75-75_avi'      
    when "mp4"  
      return 'icon_repository75-75_mp4'      
    when "mov"  
      return 'icon_repository75-75_mov'      
    when "swf"  
      return 'icon_repository75-75_flash'      
    else
      return 'icon_repository75-75_file'
    end
  end

end
