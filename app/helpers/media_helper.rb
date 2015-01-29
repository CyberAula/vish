module MediaHelper
	
	#method to print all data-url-xxx in the media player
	def getAllMediaDataUrl(media)
		all_data_url = ""

		if media.respond_to? "poster_url"
			poster_url = media.poster_url
			all_data_url += printDataUrlPoster(poster_url) + " " unless poster_url.nil?
		end

		media.sources.each do |source|
			all_data_url += printDataUrl(source[:format], source[:src]) + " "
		end

		all_data_url
	end

	#method to print all sources in the video tag
	def getAllMediaSources(media)
		all_sources_url = ""

		media.sources.each do |source|
			all_sources_url += printSourceInTag(source[:format], source[:src])
		end

		all_sources_url
	end

	#method to print data-url-format in the media player for the poster
	def printDataUrlPoster(url)
		raw string = "data-url-poster=" + url
	end

	#method to print data-url-format in the media player
	def printDataUrl(format,url)
		raw "data-url-" + format.to_s + "=" + url
	end

	#method to print source in the media tag
	def printSourceInTag(format,url)
		string = "    " + "<source src="
		string += "'" + url + "'"
		string += " type='" + Mime::Type.lookup_by_extension(format).to_s + "'>\n "
		return raw string
	end

	#method to print the poster in the embed code
	def printSourcePosterIfPresent(media)
		if media.respond_to? "poster_url"
			poster_url = media.poster_url
			return "poster='" + poster_url + "'" unless poster_url.nil?
		else
			return ""
		end
	end

end