SocialStream::Documents.setup do |config| 
  
  #Configure picture thumbnails
  config.picture_styles = {
    :"170x127#" => ["170x127#"],
    :"80x113#" => ["80x113#"], # this one preserves A4 proportion: 210x297
    :"500" => ["500>"]
  }

  config.audio_styles = { }
  config.audio_processors = []
  
  if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
    #Configure audio thumbnails
    config.audio_processors = [:ffmpeg]
    config.audio_styles[:webma] = {format: 'webm', processors: [:ffmpeg] }
    config.audio_styles[:mp3] = {format: 'mp3', processors: [:ffmpeg] }
    config.audio_styles[:wav] = {format: 'wav', processors: [:ffmpeg] }   

  end

  #Configure video thumbnails
  config.video_styles = { }
  config.video_processors = []

  if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
      config.video_processors = [:ffmpeg, :qtfaststart]
      config.video_styles[:"170x127#"] = {  :geometry => "170x127#", :format => 'png', :time => 4 }
      config.video_styles[:webm] = {  :format => 'webm' }
      config.video_styles[:flv] = {  :format => 'flv', :convert_options => { :output => {:ar =>'22050'}}}
      config.video_styles[:mp4] = {  :format => 'mp4', :convert_options => { :output => {:vcodec =>'libx264', :acodec =>"aac", :strict => "-2"}}, :streaming => true }   
  end


  #  List of mime types that have an icon defined

  # config.icon_mime_types  = {
  #    default: :default,
  #    types: [
  #      :text, :image, :audio, :video
  #    ],
  #    subtypes: [
  #      :txt, :ps, :pdf, :sla, 
  #      :odt, :odp, :ods, :doc, :ppt, :xls, :rtf,
  #      :rar, :zip,
  #      :jpeg, :gif, :png, :bmp, :xcf,
  #      :wav, :ogg, :webma, :mpeg,
  #      :flv, :webm, :mp4
  #    ]
  #  }

  config.icon_mime_types  = {
    default: :default,
    types: [
      :text, :image, :audio, :video
    ],
    subtypes: [
      #:pdf, :odt, :odp, :doc, :ppt, :xls, :docx, :pptx, :xslx, :rar,
      :pdf, :zipfile, :swf
    ]
  }

  config.subtype_classes_mime_types[:video] = [:flv, :webm, :mp4, :ogv]
  if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
    config.subtype_classes_mime_types[:video].push(:mpeg, :mov, :wmv, :m4v, :gpp, :gpp2)
  end

  config.subtype_classes_mime_types[:audio] = [:wav, :ogg, :webma, :mp3, :m4a]
  if Vish::Application.config.APP_CONFIG["services"].include? "MediaConversion"
    config.subtype_classes_mime_types[:audio].push(:aac, :aac2, :gppa, :gpa)
  end

  config.subtype_classes_mime_types[:swf] = [:swf]
  config.subtype_classes_mime_types[:zipfile] = [:zipfile]
  config.subtype_classes_mime_types[:officedoc]= [:odt, :odp, :ods, :doc, :ppt, :xls, :rtf, :pdf]
end
