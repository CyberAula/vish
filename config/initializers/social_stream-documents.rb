SocialStream::Documents.setup do |config| 
  
  #Configure picture thumbnails
  config.picture_styles = {
    :"170x127#" => ["170x127#"],
    :"80x113#" => ["80x113#"], # this one preserves A4 proportion: 210x297
    :"500" => ["500>"]
  }

  #Configure audio thumbnails
  config.audio_styles = {
    webma: {
      format: 'webm',
      processors: [:ffmpeg]
    },
    mp3: {
      format: 'mp3',
      processors: [:ffmpeg]
    },
    wav: {
      format: 'wav',
      processors: [:ffmpeg]
    }
  }

  #Configure video thumbnails
  config.video_styles = {
    :webm => {  :format => 'webm' },
    :flv  => {  :format => 'flv',
                :convert_options => { :output => {:ar =>'22050'}}
    }, 
    :mp4  => {  :format => 'mp4',
                :convert_options => { :output => {:vcodec =>'libx264', :acodec =>"aac", :strict => "-2"}},
                :streaming => true
             },
    :"170x127#" => { :geometry => "170x127#", :format => 'png', :time => 4 }
  }


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

  config.subtype_classes_mime_types[:video] = [:flv, :webm, :mp4, :mpeg, :mov, :wmv, :m4v, :ogv, :gpp, :gpp2]
  config.subtype_classes_mime_types[:audio] = [:aac, :gppa, :gpa, :wav, :ogg, :webma, :mp3]
  config.subtype_classes_mime_types[:swf] = [:swf]
  config.subtype_classes_mime_types[:zipfile] = [:zipfile]
  config.subtype_classes_mime_types[:officedoc]= [:odt, :odp, :ods, :doc, :ppt, :xls, :rtf, :pdf]
end
