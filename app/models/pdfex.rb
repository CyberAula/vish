class Pdfex < ActiveRecord::Base
   has_attached_file :attach

	def to_img(controller)
		path = self.attach.path

		splitPath = path.split("/")
		splitPath.pop()
		rootFolder = splitPath.join("/")+"/"

		splitUrl = self.attach.url.split("/")
		splitUrl.pop()
		rootUrl = splitUrl.join("/")+"/"

		splitName = self.attach.original_filename.split(".")
		splitName.pop()
		fileName = splitName.join(".")

		require 'RMagick'
		pdf = Magick::ImageList.new(path)
		pdf.write(rootFolder + fileName + ".jpg")
		imgLength = pdf.length

		imgs = Hash.new
		imgs["urls"] = []
		imgLength.times do |index|
			imgs["urls"].push(Site.current.config[:documents_hostname].to_s + rootUrl + fileName + "-" + index.to_s + ".jpg")
		end
		# Development
		# Site.current.config[:documents_hostname] = "http://localhost:3000/"
		# Site.current.save!
		# On production Site.current.config[:documents_hostname] == "http://vishub.org/"

		imgs
	end

end
