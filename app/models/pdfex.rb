class Pdfex < ActiveRecord::Base
	before_destroy :remove_files #This callback need to be before has_attached_file, to be executed before paperclip callbacks
	has_attached_file :attach
	validates_attachment_content_type :attach, :content_type =>['application/pdf'], :message => '#PDFexAPIError:1 File format is invalid'
    validates_attachment_size :attach, :in => 0.megabytes..8.megabytes, :message => '#PDFexAPIError:2 File size is too big'

	def to_img(controller)
		rootFolder = getRootFolder
		fileName = getFileName

		require 'pdf/reader'
		pdfRead = PDF::Reader.new(self.attach.path)
		if pdfRead.page_count > 90
			raise "#PDFexAPIError:3 PDF file have too many pages"
		end

		require 'RMagick'
		pdf = Magick::ImageList.new(self.attach.path){ self.density = 200 }
		pdf.write(rootFolder + fileName + (pdf.length===1 ? "-0" : "") + ".jpg")
		#imgLength = pdf.length = pdfRead.page_count

		getImgArray(pdf.length)
	end  

	def getImgArray(imgLength)
		rootFolder = getRootFolder
		rootUrl = getRootUrl
		fileName = getFileName

		if imgLength.nil?
			imgLength = %x(ls -l #{rootFolder}/*.jpg | wc -l).to_i
		end
		
		imgs = Hash.new
		imgs["urls"] = []
		imgLength.times do |index|
			imgs["urls"].push(Site.current.config[:documents_hostname].to_s + rootUrl + fileName + "-" + index.to_s + ".jpg")
		end

		#Add PDFEx Id
		imgs["pdfexID"] = self.id

		# Development
		# Site.current.config[:documents_hostname] = "http://localhost:3000/"
		# Site.current.save!
		# On production 
		# Site.current.config[:documents_hostname] = "http://vishub.org/"

		imgs
	end


	private

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

	def remove_files
		#Remove Image files
		system "rm #{getRootFolder}/*.jpg"
	end

end
