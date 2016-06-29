# encoding: utf-8
STATS_FILE_PATH = "reports/stats.txt"

namespace :stats do

  #Usage
  #Development:   bundle exec rake stats:all
  task :all => :environment do
    Rake::Task["stats:prepare"].invoke
    Rake::Task["stats:excursions"].invoke(false)
    Rake::Task["stats:excursions_ts"].invoke(false)
    Rake::Task["stats:resources"].invoke(false)
    Rake::Task["stats:users"].invoke(false)
  end

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
  end

  #Usage
  #Development:   bundle exec rake stats:excursions
  task :excursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Excursions Stats"

    allDates = []
    allExcursionsByDate = []
    for year in 2012..2016
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        excursions = Excursion.where(:created_at => startDate..endDate)
        allDates.push(startDate.strftime("%B %Y"))
        allExcursionsByDate.push(excursions)
      end
    end

    #Created excursions
    createdExcursions = []
    accumulativeCreatedExcursions = []
    publishedExcursions = []
    allExcursionsByDate.each_with_index do |excursions,index|
      nCreated = excursions.order('id DESC').first.id rescue 0
      accumulativeCreatedExcursions.push(nCreated)
      nCreated = (nCreated - accumulativeCreatedExcursions[index-1]) unless index==0 or nCreated == 0
      createdExcursions.push(nCreated)
      publishedExcursions.push(excursions.count)
    end

    #Accumulative Published Excursions
    accumulativePublishedExcursions = []
    publishedExcursions.each_with_index do |n,index|
      accumulativePublishedExcursions.push(n)
      accumulativePublishedExcursions[index] = accumulativePublishedExcursions[index] + accumulativePublishedExcursions[index-1] unless index==0
    end

    #Visits, downloads and likes
    allExcursions = Excursion.all
    visits = allExcursions.map{|e| e.visit_count}
    downloads = allExcursions.map{|e| e.download_count}
    likes = allExcursions.map{|e| e.like_count}

    totalVisits = visits.sum
    totalDownloads = downloads.sum
    totalLikes = likes.sum

    filePath = "reports/excursions_stats.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Presentations Stats") do |sheet|
        rows = []
        rows << ["Presentations Stats"]
        rows << ["Date","Created Presentations","Published Presentations","Accumulative Created Presentations","Accumulative Published Presentations"]
        rowIndex = rows.length
        
        rows += Array.new(createdExcursions.length).map{|e|[]}
        createdExcursions.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],createdExcursions[i],publishedExcursions[i],accumulativeCreatedExcursions[i],accumulativePublishedExcursions[i]]
        end

        rows << []
        rows << ["Total Visits","Total Downloads","Total Likes"]
        rows << [totalVisits,totalDownloads,totalLikes]
        rows << []
        rows << ["Visits","Downloads","Likes"]
        rowIndex = rows.length
        rows += Array.new(allExcursions.length).map{|e|[]}
        allExcursions.each_with_index do |e,i|
          rows[rowIndex+i] = [visits[i],downloads[i],likes[i]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end

      prepareFile(filePath)
      p.serialize(filePath)

      puts("Task Finished. Results generated at " + filePath)
    end
  end

  #Usage
  #Development:   bundle exec rake stats:excursions_ts
  task :excursions_ts, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Excursions Stats (Tracking System)"

    allDates = []
    allTimes = []
    for year in 2012..2016
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        vvEntries = TrackingSystemEntry.where(:app_id=>"ViSH Viewer",:created_at => startDate..endDate)
        
        time = 0
        vvEntries.find_each batch_size: 1000 do |e|
          d = JSON(e["data"]) rescue {}
          time = time + d["duration"].to_i if LoInteraction.isValidInteraction?(d)
        end
        allTimes.push((time/3600.to_f).ceil)
        allDates.push(startDate.strftime("%B %Y"))
      end
    end

    accumulativeTimes = []
    allTimes.each_with_index do |n,index|
      accumulativeTimes.push(n)
      accumulativeTimes[index] = accumulativeTimes[index] + accumulativeTimes[index-1] unless index==0
    end

    filePath = "reports/excursions_stats_ts.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Presentations Stats TS") do |sheet|
        rows = []
        rows << ["Presentations Stats (Tracking System)"]
        rows << ["Date","Time","Accumulative Time"]
        rowIndex = rows.length
        
        rows += Array.new(allTimes.length).map{|e|[]}
        allTimes.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],allTimes[i],accumulativeTimes[i]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end

      prepareFile(filePath)
      p.serialize(filePath)

      puts("Task Finished. Results generated at " + filePath)
    end
  end

  # #Usage
  # #Development:   bundle exec rake stats:check_resources
  # task :check_resources, [:prepare] => :environment do |t,args|
  #   allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop", "Category"] + VishConfig.getResourceModels).uniq
  #   allResourceTypes.each do |type|
  #     allResources = ActivityObject.where("object_type in (?)", [type]).order("id DESC").map{|ao| ao.object}
  #     maxIndex = allResources.length-1
  #     allResources.each_with_index do |resource,index|
  #       unless (index+1) > maxIndex
  #         binding.pry if (allResources[index+1].id - allResources[index].id > 5)
  #         binding.pry if (allResources[index+1].created_at - allResources[index].created_at > (3600*24))
  #         binding.pry if (allResources[index+1].activity_object.created_at - allResources[index].activity_object.created_at > (3600*24))
  #       end
  #     end
  #   end
  # end

  #Usage
  #Development:   bundle exec rake stats:resources
  task :resources, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Resources Stats"

    allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop", "Category"] + VishConfig.getResourceModels).uniq
    allDates = []
    allResourcesByDateAndType = []
    for year in 2012..2016
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        allDates.push(startDate.strftime("%B %Y"))
        allResourcesByDateAndType.push({})
        gindex = (allResourcesByDateAndType.length - 1)
        # resources = ActivityObject.where("object_type in (?)", allResourceTypes).where(:created_at => startDate..endDate)
        allResourceTypes.each do |type|
          allResourcesByDateAndType[gindex][type] = ActivityObject.where("object_type in (?)", [type]).where(:created_at => startDate..endDate).map{|ao| ao.object}
        end
      end
    end

    #Uploaded Resources by Type
    uploadedResourcesByType = []
    accumulativeUploadedResourcesByType = []

    allResourcesByDateAndType.each_with_index do |resourcesHash,index|
      accumulativeUploadedResourcesByType.push({})
      uploadedResourcesByType.push({})
      allResourceTypes.each do |type|
        if accumulativeUploadedResourcesByType[index-1].blank? or accumulativeUploadedResourcesByType[index-1][type].blank?
          prevACC = 0
        else
          prevACC = accumulativeUploadedResourcesByType[index-1][type]
        end

        if resourcesHash[type].blank?
          nACC = prevACC
        else
          nACC = resourcesHash[type].max_by{|ao| ao.id}.id
        end

        accumulativeUploadedResourcesByType[index][type] = nACC

        nUploaded = (nACC - prevACC)
        uploadedResourcesByType[index][type] = nUploaded
      end
    end

    #Uploaded Resources
    uploadedResources = []
    accumulativeUploadedResources = []

    uploadedResourcesByType.each_with_index do |resourcesHash,index|
      nUploaded = 0
      allResourceTypes.each do |type|
        nUploaded = nUploaded + resourcesHash[type]
      end
      uploadedResources.push(nUploaded)
    end

    accumulativeUploadedResourcesByType.each_with_index do |resourcesHash,index|
      nUploaded = 0
      allResourceTypes.each do |type|
        nUploaded = nUploaded + resourcesHash[type]
      end
      accumulativeUploadedResources.push(nUploaded)
    end


    #Analyze different types of documents: "Picture", "Video", "Document", "Officedoc", "Swf", "Audio", "Zipfile"
    allDocumentTypes = ["Picture", "Video", "Document", "Officedoc", "Swf", "Audio", "Zipfile"]
    allDocumentsByDateAndType = []
    allResourcesByDateAndType.each_with_index do |resourcesHash,index|
      allDocumentsByDateAndType.push({})
      allDocumentTypes.each do |docType|
        allDocumentsByDateAndType[index][docType] = []
      end
      resourcesHash["Document"].each do |doc|
        allDocumentsByDateAndType[index][doc.class.name].push(doc)
      end
    end

    #Uploaded Documents by Type
    uploadedDocumentsByType = []
    accumulativeUploadedDocumentsByType = []

    allDocumentsByDateAndType.each_with_index do |documentsHash,index|
      uploadedDocumentsByType.push({})
      accumulativeUploadedDocumentsByType.push({})

      allDocumentTypes.each do |type|
        nUploaded = documentsHash[type].length
        uploadedDocumentsByType[index][type] = nUploaded

        if accumulativeUploadedDocumentsByType[index-1].blank? or accumulativeUploadedDocumentsByType[index-1][type].blank?
          prevACC = 0
        else
          prevACC = accumulativeUploadedDocumentsByType[index-1][type]
        end

        nACC = prevACC + nUploaded
        accumulativeUploadedDocumentsByType[index][type] = nACC
      end
    end

    # #Visits, downloads and likes
    allResources = ActivityObject.where("object_type in (?)", allResourceTypes).map{|ao| ao.object}
    visits = allResources.map{|e| e.visit_count}
    downloads = allResources.map{|e| e.download_count}
    likes = allResources.map{|e| e.like_count}

    totalVisits = visits.sum
    totalDownloads = downloads.sum
    totalLikes = likes.sum

    filePath = "reports/resources_stats.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "Resources Stats") do |sheet|
        rows = []
        rows << ["Resources Stats"]
        rows << ["Date","Uploaded Resources","Accumulative Uploaded Resources"]
        rowIndex = rows.length
        
        rows += Array.new(uploadedResources.length).map{|e|[]}
        uploadedResources.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],uploadedResources[i],accumulativeUploadedResources[i]]
        end

        rows << []
        rows << ["Resource type","Total Uploaded Resources"]
        allResourceTypes.each do |type|
          rows << [type,accumulativeUploadedResourcesByType[accumulativeUploadedResourcesByType.length-1][type]]
        end

        allResourceTypes.each do |type|
          rows << []
          rows << ["Resources Stats: " + type]
          rows << ["Date","Uploaded Resources","Accumulative Uploaded Resources"]
          uploadedResourcesByType.each_with_index do |resourcesHash,i|
            rows << [allDates[i],resourcesHash[type],accumulativeUploadedResourcesByType[i][type]]
          end
        end

        allDocumentTypes.each do |type|
          dName = type
          rows << []
          rows << ["Documents estimation: " + dName]
          rows << ["Date","Uploaded " + dName,"Accumulative Uploaded " + dName]
          uploadedDocumentsByType.each_with_index do |documentsHash,i|
            rows << [allDates[i],documentsHash[type],accumulativeUploadedDocumentsByType[i][type]]
          end
        end

        rows << []
        rows << ["Visits, Downloads and Likes"]
        rows << ["Total Visits","Total Downloads","Total Likes"]
        rows << [totalVisits,totalDownloads,totalLikes]
        rows << []
        rows << ["Visits","Downloads","Likes"]
        rowIndex = rows.length
        rows += Array.new(allResources.length).map{|e|[]}
        allResources.each_with_index do |e,i|
          rows[rowIndex+i] = [visits[i],downloads[i],likes[i]]
        end

        rows.each do |row|
          sheet.add_row row
        end
      end

      prepareFile(filePath)
      p.serialize(filePath)

      puts("Task Finished. Results generated at " + filePath)
    end
  end

  # task :resources, [:prepare] => :environment do |t,args|
  #   args.with_defaults(:prepare => true)

  #   if args.prepare
  #     Rake::Task["stats:prepare"].invoke
  #   end

  #   writeInStats("")
  #   writeInStats("Resources Report")
  #   writeInStats("")

  #   allCreatedResources = []
  #   for year in 2012..2014
  #     12.times do |index|
  #       month = index+1
  #       # date = DateTime.new(params[:year],params[:month],params[:day])
  #       startDate = DateTime.new(year,month,1)
  #       endDate = startDate.next_month
  #       resources = Document.where(:created_at => startDate..endDate)
  #       writeInStats(startDate.strftime("%B %Y"))
  #       allCreatedResources.push(resources)
  #     end
  #   end

  #   writeInStats("")
  #   writeInStats("Created Resources")
  #   allCreatedResources.each do |createdResources|
  #     writeInStats(createdResources.count)
  #   end

  #   writeInStats("")
  #   writeInStats("Accumulative Created Resources")
  #   accumulativeResources = 0
  #   allCreatedResources.each do |createdResources|
  #     accumulativeResources = accumulativeResources + createdResources.count
  #     writeInStats(accumulativeResources)
  #   end

  #   #Resources type
  #   writeInStats("")
  #   writeInStats("Type of Resources")
  #   resourcesReport = getResourcesByType(Document.all)

  #   resourcesReport.each do |resourceReport|
  #     writeInStats(resourceReport["resourceType"].to_s)
  #     writeInStats(resourceReport["percent"].to_s)
  #   end

  # end

  task :users, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Users Report")
    writeInStats("")

    allUsers = []
    for year in 2012..2014
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        users = User.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allUsers.push(users)
      end
    end

    writeInStats("")
    writeInStats("Registered Users")
    allUsers.each do |users|
      writeInStats(users.count)
    end

    writeInStats("")
    writeInStats("Accumulative Registered Users")
    accumulativeUsers = 0
    allUsers.each do |users|
      accumulativeUsers = accumulativeUsers + users.count
      writeInStats(accumulativeUsers)
    end

  end

  def getResourcesByType(resources)
    results = []
    resourcesType = Hash.new
    #resourcesType['file_content_type'] = [resources]

    resources.each do |resource|
      if resource.file_content_type
        if resourcesType[resource.file_content_type] == nil
          resourcesType[resource.file_content_type] = []
        end
        resourcesType[resource.file_content_type].push(resource)
      end
    end

    resourcesType.each do |e|
      key = e[0]
      value = e[1]

      result = Hash.new
      result["resourceType"] = key
      result["percent"] = ((value.count/resources.count.to_f)*100).round(3)
      results.push(result)
    end

    results
  end

  def writeInStats(line)
    write(line,STATS_FILE_PATH)
  end

end
