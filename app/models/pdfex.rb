class Pdfex < ActiveRecord::Base
	has_attached_file :attach
	validates_attachment_content_type :attach, :content_type =>['application/pdf'],
                                              :message => 'Only PDF is allowed.'

	def to_img(controller)
		rootFolder = getRootFolder
		fileName = getFileName

		require 'RMagick'
		pdf = Magick::ImageList.new(self.attach.path)
		pdf.write(rootFolder + fileName + ".jpg")
		# imgLength = pdf.length

		getImgArray
	end

	def getImgArray
		rootFolder = getRootFolder
		rootUrl = getRootUrl
		fileName = getFileName

		imgLength = %x(ls -l #{rootFolder}/*.jpg | wc -l).to_i

		imgs = Hash.new
		imgs["urls"] = []
		imgLength.times do |index|
			imgs["urls"].push(Site.current.config[:documents_hostname].to_s + rootUrl + fileName + "-" + index.to_s + ".jpg")
		end

		# Development
		# Site.current.config[:documents_hostname] = "http://localhost:3000/"
		# Site.current.save!
		# On production 
		# Site.current.config[:documents_hostname] = "http://vishub.org/"

		imgs
	end


	def getRootFolder
		splitPath = self.attach.path.split("/")
		splitPath.pop()
		rootFolder = splitPath.join("/")+"/"
	end

	def getRootUrl
		splitUrl = self.attach.url.split("/")
		splitUrl.pop()
		rootUrl = splitUrl.join("/")+"/"
	end

	def getFileName
		splitName = self.attach.original_filename.split(".")
		splitName.pop()
		fileName = splitName.join(".")
	end

end
