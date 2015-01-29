module MediaHelper
	
	#method to print all data-url-xxx in the media player
	#only if the media has been converted or it is xxx format
	def getAllVideoDataUrl(media)
		all_data_url = ""
		all_data_url += printDataUrlIfPresent(media, :webm) + " "
		all_data_url += printDataUrlIfPresent(media, :flv) + " "
		all_data_url += printDataUrlIfPresent(media, :mp4) + " "
		all_data_url += printDataUrlPosterIfPresent(media, :png, '170x127#') + " "
	end

	#method to print all sources in the video tag
	def getAllVideoSources(media)
		all_sources_url = ""
		all_sources_url += printSourceIfPresent(media, :webm)
		all_sources_url += printSourceIfPresent(media, :flv)
		all_sources_url += printSourceIfPresent(media, :mp4)
	end

	#method to print all data-url-xxx in the media player
	#only if the media has been converted or it is xxx format
	def getAllAudioDataUrl(media)
		all_data_url = ""
		all_data_url += printDataUrlIfPresent(media, :webma) + " "
		all_data_url += printDataUrlIfPresent(media, :mp3) + " "
	end

	#method to print all sources in the audio tag
	def getAllAudioSources(media)
		all_sources_url = ""
		all_sources_url += printSourceIfPresent(media, :webma)
		all_sources_url += printSourceIfPresent(media, :mp3)
		all_sources_url += printSourceIfPresent(media, :wav)
	end

	#method to print data-url-webm in the media player
	#only if the media has been converted or it is the format
	def printDataUrlIfPresent(media, format)
		if available_services.include?("MediaConversion") || media.format == format
			string = "data-url-" + format.to_s + "=" + Vish::Application.config.full_domain + polymorphic_path(media, :format => format)
			return raw string
		else
			return ""
		end
	end

	#method to print data-url-webm in the media player
	#only if the media has been converted or it is the format
	def printDataUrlPosterIfPresent(media, format, style)
		if available_services.include?("MediaConversion")
			string = "data-url-poster=" + Vish::Application.config.full_domain + polymorphic_path(media, :format => format, :style => style)
			return raw string
		else
			return ""
		end	
	end

	#method to print source in the media tag
	#only if the media has been converted or it is the format
	def printSourceIfPresent(media, format)
		if available_services.include?("MediaConversion") || media.format == format
			string = "    " + "<source src="
			string += "'" + Vish::Application.config.full_domain + polymorphic_path(media, :format => format) + "'"
			string += " type='"+Mime::Type.lookup_by_extension(format).to_s+"'>\n "
			return raw string
		else
			return ""
		end	
	end

	#method to print data-url-webm in the media player
	#only if the media has been converted or it is the format
	def printSourcePosterIfPresent(media, format, style)
		if available_services.include?("MediaConversion")
			string = "poster='" + Vish::Application.config.full_domain + polymorphic_path(media, :format => format, :style => style) + "'"
			return raw string
		else
			return ""
		end	
	end

end