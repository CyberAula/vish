# encoding: utf-8

namespace :clean do

  #Usage
  #Development:   bundle exec rake clean:pdfexes
  #In production: bundle exec rake clean:pdfexes RAILS_ENV=production
  task :pdfexes => :environment do

    puts "#####################################"
    puts "Cleaning PDFExes (PDF conversions)"
    puts "#####################################"

    usedPdfexes = Hash.new
    # usedPdfexes["pdfexID"] = [1,2,3,8,#slideused]

    #Get all excursions
    excursions = Excursion.all
    excursions.each do |excursion|
      begin
        eJson = JSON(excursion.json)
        eJson["slides"].each do |slide|
          sElements = slide["elements"]
          if sElements != nil
            sElements.each do |el|
              if el["type"]=="image" and el["options"].class == Hash and el["options"]["vishubPdfexId"].class == String
                isNumber = (true if Integer(el["options"]["vishubPdfexId"]) rescue false)
                if isNumber
                  #Mark this pdfex as used
                  pdfexId = Integer(el["options"]["vishubPdfexId"])
                  begin
                    slideIndex = Integer(el["body"].split("/").pop().split(".jpg")[0].split("-").pop());
                    #slideNumber = slideIndex+1
                  rescue
                    #slideIndex couldn't be determine
                    continue
                  end
                  
                  if usedPdfexes[pdfexId] == nil
                    usedPdfexes[pdfexId] = []
                  end
                  usedPdfexes[pdfexId].push(slideIndex)
                end
              end
            end
          end
        end
      rescue Exception => e
        puts "Exception with excursion id:"
        puts excursion.id.to_s
        puts "Exception message"
        puts e.message
      end
    end

    #All PdfexesUsed in usedPdfexes

    #Keep recent PDFExes (can be in use right now) (select old pdfexes created two days ago and longer)
    pdfexes = Pdfex.all(:conditions => ["created_at <= ?", Date.today-1])
    #Keep permanent pdfexes
    pdfexes = pdfexes.reject { |p| p.permanent == true}

    #PDFexes to remove
    pdfexesToRemove = pdfexes.select{ |pdfexe| !usedPdfexes.keys.include? pdfexe.id}
    pdfexesToRemove.map { |pdfexe| pdfexe.destroy }

    #PDFexes to keep, check unused slides
    pdfexesToKeep = pdfexes.select{ |pdfexe| usedPdfexes.keys.include? pdfexe.id}
    pdfexesToKeep.map { |pdfexe|
      usedSlidesIndexes = usedPdfexes[pdfexe.id]
      pdfexe.pcount.times do |i|
        if !usedSlidesIndexes.include? i
          #Image not used, check if exists
          filePath = pdfexe.getRootFolder + pdfexe.getFullFileNameForIndex(i)
          if File.exists?(filePath)
            #Remove file
            FileUtils.rm(filePath)
          end
        end      
      end
    }

    puts "#####################################"
    puts "Task Finished"
    puts "#####################################"
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end


