# encoding: utf-8
STATS_FILE_PATH = "reports/stats.txt"

namespace :stats do

  #Usage
  #Development:   bundle exec rake stats:all
  task :all => :environment do
    Rake::Task["stats:prepare"].invoke
    Rake::Task["stats:excursions"].invoke(false)
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
    for year in 2012..2017
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
      lastAcCreated = (index > 0 ? accumulativeCreatedExcursions[index-1] : 0)
      acCreated = excursions.order('id DESC').first.id rescue 0
      acCreated = lastAcCreated if acCreated == 0
      accumulativeCreatedExcursions.push(acCreated)
      nCreated = acCreated - lastAcCreated
      createdExcursions.push(nCreated)
      publishedExcursions.push(excursions.where("draft=false").count)
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
    totalLearningHours = allExcursions.map{|e| e.lo_interaction}.compact.map{|i| ((i.tlo * i.nsamples)/3600.to_f).ceil}.compact.sum

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
        rows << ["Total Visits","Total Downloads","Total Likes","Total Learning Hours"]
        rows << [totalVisits,totalDownloads,totalLikes,totalLearningHours]
        rows << []
        rows << ["Id","Draft","Visits","Downloads","Likes","Learning Hours"]
        rowIndex = rows.length
        rows += Array.new(allExcursions.length).map{|e|[]}
        allExcursions.each_with_index do |e,i|
          #Calculate Learning time
          interaction = e.lo_interaction
          if interaction.nil?
            loTime = 0
          else
            loTime = ((interaction.tlo * interaction.nsamples)/3600.to_f).ceil
          end
          rows[rowIndex+i] = [e.id,e.draft.to_s,visits[i],downloads[i],likes[i],loTime]
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
  #Development:   bundle exec rake stats:check_resources
  task :check_resources, [:prepare] => :environment do |t,args|
    allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop"] + VishConfig.getResourceModels).uniq
    # allResourceTypes += ["Category"]
    allResourceTypes.each do |type|
      allResources = ActivityObject.where("object_type in (?)", [type]).order("id DESC").map{|ao| ao.object}
      maxIndex = allResources.length-1
      allResources.each_with_index do |resource,index|
        unless (index+1) > maxIndex
          rName = allResources[index].class.name + ":" + allResources[index].id.to_s
          if (allResources[index+1].id - allResources[index].id > 5)
            puts "Wrong sequence with " + rName
          end

          if allResources[index+1].created_at.blank? or allResources[index].created_at.blank?
            if allResources[index].created_at.blank?
              puts "Created_at nil for " + rName
            end
          else
            if (allResources[index+1].created_at - allResources[index].created_at > (3600*24))
              puts "Wrong created_at timestamp for " + rName
            end
          end
         
          if allResources[index+1].activity_object.created_at.blank? or allResources[index].activity_object.created_at.blank?
            if allResources[index].activity_object.created_at.blank?
              puts "Created_at nil for activity object of " + rName
            end
          else
            if (allResources[index+1].activity_object.created_at - allResources[index].activity_object.created_at > (3600*24))
              puts "Wrong created_at timestamp for activity object of " + rName
            end
          end
        end
      end
    end
  end

  #Usage
  #Development:   bundle exec rake stats:resources
  task :resources, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Resources Stats"

    allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop"] + VishConfig.getResourceModels).uniq
    # allResourceTypes += ["Category"]
    allDates = []
    allResourcesByDateAndType = []
    for year in 2012..2017
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

    #Published Resources by Type
    publishedResourcesByType = []
    accumulativePublishedResourcesByType = []

    allResourcesByDateAndType.each_with_index do |resourcesHash,index|
      accumulativePublishedResourcesByType.push({})
      publishedResourcesByType.push({})
      allResourceTypes.each do |type|
        if accumulativePublishedResourcesByType[index-1].blank? or accumulativePublishedResourcesByType[index-1][type].blank?
          prevACC = 0
        else
          prevACC = accumulativePublishedResourcesByType[index-1][type]
        end

        nPublished = resourcesHash[type].select{|o| o.scope==0}.length
        accumulativePublishedResourcesByType[index][type] = prevACC + nPublished
        publishedResourcesByType[index][type] = nPublished
      end
    end

    #Published Resources
    publishedResources = []
    accumulativePublishedResources = []

    publishedResourcesByType.each_with_index do |resourcesHash,index|
      nPublished = 0
      allResourceTypes.each do |type|
        nPublished = nPublished + resourcesHash[type]
      end
      publishedResources.push(nPublished)
    end

    accumulativePublishedResourcesByType.each_with_index do |resourcesHash,index|
      nPublished = 0
      allResourceTypes.each do |type|
        nPublished = nPublished + resourcesHash[type]
      end
      accumulativePublishedResources.push(nPublished)
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

    #Published Documents by Type
    publishedDocumentsByType = []
    accumulativePublishedDocumentsByType = []

    allDocumentsByDateAndType.each_with_index do |documentsHash,index|
      publishedDocumentsByType.push({})
      accumulativePublishedDocumentsByType.push({})

      allDocumentTypes.each do |type|
        nPublished = documentsHash[type].length
        publishedDocumentsByType[index][type] = nPublished

        if accumulativePublishedDocumentsByType[index-1].blank? or accumulativePublishedDocumentsByType[index-1][type].blank?
          prevACC = 0
        else
          prevACC = accumulativePublishedDocumentsByType[index-1][type]
        end

        nACC = prevACC + nPublished
        accumulativePublishedDocumentsByType[index][type] = nACC
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
        
        rows << ["Date","Uploaded Resources","Accumulative Uploaded Resources","Published Resources","Accumulative Published Resources"]
        rowIndex = rows.length
        rows += Array.new(uploadedResources.length).map{|e|[]}
        uploadedResources.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],uploadedResources[i],accumulativeUploadedResources[i],publishedResources[i],accumulativePublishedResources[i]]
        end

        rows << []
        rows << ["Resource type","Total Uploaded Resources","Total Published Resources"]
        allResourceTypes.each do |type|
          rows << [type,accumulativeUploadedResourcesByType[accumulativeUploadedResourcesByType.length-1][type],accumulativePublishedResourcesByType[accumulativePublishedResourcesByType.length-1][type]]
        end

        allResourceTypes.each do |type|
          rows << []
          rows << ["Resources Stats: " + type]
          rows << ["Date","Uploaded Resources","Accumulative Uploaded Resources","Published Resources","Accumulative Published Resources"]
          uploadedResourcesByType.each_with_index do |resourcesHash,i|
            rows << [allDates[i],uploadedResourcesByType[i][type],accumulativeUploadedResourcesByType[i][type],publishedResourcesByType[i][type],accumulativePublishedResourcesByType[i][type]]
          end
        end

        allDocumentTypes.each do |type|
          dName = type
          rows << []
          rows << ["Documents estimation: " + dName]
          rows << ["Date","Published " + dName,"Accumulative Published " + dName]
          publishedDocumentsByType.each_with_index do |documentsHash,i|
            rows << [allDates[i],publishedDocumentsByType[i][type],accumulativePublishedDocumentsByType[i][type]]
          end
        end

        rows << []
        rows << ["Visits, Downloads and Likes"]
        rows << ["Total Visits","Total Downloads","Total Likes"]
        rows << [totalVisits,totalDownloads,totalLikes]
        rows << []
        # rows << ["Visits","Downloads","Likes"]
        rows << ["AO Id","Scope","Object type","Visits","Downloads","Likes"]
        rowIndex = rows.length
        rows += Array.new(allResources.length).map{|r|[]}
        allResources.each_with_index do |r,i|
          rows[rowIndex+i] = [r.id,r.scope,r.object_type,visits[i],downloads[i],likes[i]]
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
  #Development:   bundle exec rake stats:users
  task :users, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "Users Stats"

    allDates = []
    allUsersByDate = []
    for year in 2012..2017
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        users = User.where(:created_at => startDate..endDate)
        allDates.push(startDate.strftime("%B %Y"))
        allUsersByDate.push(users)
      end
    end

    #Created users
    createdUsers = []
    accumulativeCreatedUsers = []
    allUsersByDate.each_with_index do |users,index|
      lastAcCreated = (index > 0 ? accumulativeCreatedUsers[index-1] : 0)
      acCreated = users.order('id DESC').first.id rescue 0
      acCreated = lastAcCreated if acCreated == 0
      accumulativeCreatedUsers.push(acCreated)
      nCreated = acCreated - lastAcCreated
      createdUsers.push(nCreated)
    end

    #Registered users
    registeredUsers = []
    accumulativeRegisteredUsers = []
    allUsersByDate.each_with_index do |users,index|
      nRegistered = users.count
      lastAcRegistered = (index > 0 ? accumulativeRegisteredUsers[index-1] : 0)
      acRegistered = lastAcRegistered + nRegistered
      registeredUsers.push(nRegistered)
      accumulativeRegisteredUsers.push(acRegistered)
    end

    #Registered contributors
    registeredContributors = []
    accumulativeRegisteredContributors = []
    allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop"] + VishConfig.getResourceModels).uniq
    # allResourceTypes += ["Category"]
    allUsersByDate.each_with_index do |users,index|
      nRegistered = users.select{|u| ActivityObject.authored_by(u).where("object_type in (?) and scope=0", allResourceTypes).count > 0}.length
      lastAcRegistered = (index > 0 ? accumulativeRegisteredContributors[index-1] : 0)
      acRegistered = lastAcRegistered + nRegistered
      registeredContributors.push(nRegistered)
      accumulativeRegisteredContributors.push(acRegistered)
    end

    #Registered authors
    registeredAuthors = []
    accumulativeRegisteredAuthors = []
    authoredResourceTypes = ["Excursion", "Workshop"]
    allUsersByDate.each_with_index do |users,index|
      nRegistered = users.select{|u| ActivityObject.authored_by(u).where("object_type in (?) and scope=0", authoredResourceTypes).count > 0}.length
      lastAcRegistered = (index > 0 ? accumulativeRegisteredAuthors[index-1] : 0)
      acRegistered = lastAcRegistered + nRegistered
      registeredAuthors.push(nRegistered)
      accumulativeRegisteredAuthors.push(acRegistered)
    end

    filePath = "reports/users_stats.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "User Stats") do |sheet|
        rows = []
        rows << ["User Stats"]
        rows << ["Date","Created Users","Accumulative Created Users","Registered Users","Accumulative Registered Users","Registered Contributors","Accumulative Registered Contributors","Registered Authors","Accumulative Registered Authors"]
        rowIndex = rows.length
        
        rows += Array.new(createdUsers.length).map{|e|[]}
        createdUsers.each_with_index do |n,i|
          rows[rowIndex+i] = [allDates[i],createdUsers[i],accumulativeCreatedUsers[i],registeredUsers[i],accumulativeRegisteredUsers[i],registeredContributors[i],accumulativeRegisteredContributors[i],registeredAuthors[i],accumulativeRegisteredAuthors[i]]
        end

        #Resources published by Registered Contributors
        rows << []
        rows << ["Registered Contributors"]
        rows << ["Author Id","Number of published resources"]
        User.all.map{|u| [u.actor_id,ActivityObject.authored_by(u).where("object_type in (?) and scope=0", allResourceTypes).count]}.select{|uM| uM[1] > 0}.each do |uM|
          rows << [uM[0],uM[1]]
        end

        #Resources created by Registered Authors
        rows << []
        rows << ["Registered Authors"]
        rows << ["Author Id","Number of created resources"]
        User.all.map{|u| [u.actor_id,ActivityObject.authored_by(u).where("object_type in (?) and scope=0", authoredResourceTypes).count]}.select{|uM| uM[1] > 0}.each do |uM|
          rows << [uM[0],uM[1]]
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
  #Development:   bundle exec rake stats:general
  task :general, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)
    Rake::Task["stats:prepare"].invoke if args.prepare

    puts "General Stats"

    allResourceTypes = (["Document", "Webapp", "Scormfile", "Imscpfile", "Link", "Embed", "Writing", "Excursion", "Workshop"] + VishConfig.getResourceModels).uniq
    # allResourceTypes += ["Category"]

    allDates = []
    allRegisteredUsersByDate = []
    allPublishedResourcesByDate = []
    for year in 2012..2017
      12.times do |index|
        month = index+1
        # date = DateTime.new(params[:year],params[:month],params[:day])
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month
        users = User.where(:created_at => startDate..endDate)
        allRegisteredUsersByDate.push(users)
        resources = ActivityObject.where(:created_at => startDate..endDate).where("object_type in (?) and scope=0", allResourceTypes)
        allPublishedResourcesByDate.push(resources)

        allDates.push(startDate.strftime("%B %Y"))
      end
    end

    #Registered users
    registeredUsers = []
    accumulativeRegisteredUsers = []
    allRegisteredUsersByDate.each_with_index do |users,index|
      nRegistered = users.count
      lastAcRegistered = (index > 0 ? accumulativeRegisteredUsers[index-1] : 0)
      acRegistered = lastAcRegistered + nRegistered
      registeredUsers.push(nRegistered)
      accumulativeRegisteredUsers.push(acRegistered)
    end

    #Published resources
    publishedResources = []
    accumulativePublishedResources = []
    allPublishedResourcesByDate.each_with_index do |resources,index|
      nPublished = resources.count
      lastAcPublished = (index > 0 ? accumulativePublishedResources[index-1] : 0)
      acPublished = lastAcPublished + nPublished
      publishedResources.push(nPublished)
      accumulativePublishedResources.push(acPublished)
    end

    #Visits to published resources
    nVisits = allPublishedResourcesByDate.map{|aos| aos.map{|ao| ao.visit_count}.sum }.sum

    filePath = "reports/general_stats.xlsx"
    prepareFile(filePath)

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "General Stats") do |sheet|
        rows = []
        rows << ["User Stats"]
        rows << ["Date","Registered Users","Published Resources","Resource visits"]
        rows << ["","","",nVisits]
        rowIndex = rows.length
        
        rows += Array.new(allDates.length).map{|e|[]}
        allDates.each_with_index do |date,i|
          rows[rowIndex+i] = [date,accumulativeRegisteredUsers[i],accumulativePublishedResources[i]]
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

end