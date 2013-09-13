module LinkHelper
	def completeURL(url)
		if !url.start_with? ("http://")
			"http://" + url 
		else
			url
		end
	end
end
