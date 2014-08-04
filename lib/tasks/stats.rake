# encoding: utf-8
STATS_FILE_PATH = "reports/stats.txt";

namespace :stats do

  #Usage
  #Development:   bundle exec rake stats:all
  #In production: bundle exec rake stats:all RAILS_ENV=production
  task :all => :environment do
    Rake::Task["stats:prepare"].invoke
    Rake::Task["stats:excursions"].invoke(false)
    Rake::Task["stats:resources"].invoke(false)
    Rake::Task["stats:users"].invoke(false)
  end

  task :prepare do
    require "#{Rails.root}/lib/task_utils"
    prepareFile(STATS_FILE_PATH)
    writeInStats("ViSH Stats Report")
  end

  task :excursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Excursions Report")
    writeInStats("")

    allCreatedExcursions = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        excursions = Excursion.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allCreatedExcursions.push(excursions);
      end
    end

    writeInStats("")
    writeInStats("Total Views")

    allTotalViews = [];
    allCreatedExcursions.each do |excursions|
      totalViews = getViews(excursions)
      allTotalViews.push(totalViews);
      writeInStats(totalViews)
    end

    writeInStats("")
    writeInStats("Total Accumulative Views")
    accumulativeViews = 0;
    allTotalViews.each do |totalViews|
      accumulativeViews = accumulativeViews + totalViews
      writeInStats(accumulativeViews)
    end

    writeInStats("")
    writeInStats("Created Excursions")
    allCreatedExcursions.each do |createdExcursions|
      writeInStats(createdExcursions.count)
    end

    writeInStats("")
    writeInStats("Accumulative Created Excursions")
    accumulativeExcursions = 0;
    allCreatedExcursions.each do |createdExcursions|
      accumulativeExcursions = accumulativeExcursions + createdExcursions.count
      writeInStats(accumulativeExcursions)
    end

    # Evaluations
    evaluations = [];
    6.times do |index|
      evaluations.push(ExcursionEvaluation.average("answer_"+index.to_s).to_f.round(2));
    end
    evaluationsAverage = getAverage(evaluations)
 
    writeInStats("")
    writeInStats("Evaluations: Average")
    writeInStats("Content")
    writeInStats("Design")
    writeInStats("Motivation")
    writeInStats("Engagement")
    writeInStats("Interdisciplinary")
    writeInStats("Use again")
    writeInStats("All")

    evaluations.each do |evaluation|
      writeInStats(evaluation);
    end
    writeInStats(evaluationsAverage);


    # Evaluations evolution
    writeInStats("")
    writeInStats("Evaluations: Evolution")
    writeInStats("[Content,Design,Motivation,Engagement,Interdisciplinary,Use again]")

    averageEvalsList = [];
    allCreatedExcursions.each do |createdExcursions|
      accumulativeEval = [0,0,0,0,0,0];
      evaluationsCount = 0;
      createdExcursions.each do |excursion|
        if excursion.evaluations.length > 0
          evaluations = excursion.averageEvaluation
          for i in 0..accumulativeEval.count-1
            accumulativeEval[i] = accumulativeEval[i] + evaluations[i];
          end
          evaluationsCount = evaluationsCount+1
        end
      end
      averageEval = [0,0,0,0,0,0];
      for i in 0..accumulativeEval.count-1
        if evaluationsCount > 0
          averageEval[i] = (accumulativeEval[i]/evaluationsCount.to_f).round(2);
        else
          averageEval[i] = nil
        end
      end
      averageEvalsList.push(averageEval);
      writeInStats(averageEval)
    end

    writeInStats("")
    writeInStats("Average of all evaluations")
    averageEvalsList.each do |averageEvals|
      averageEval = getAverage(averageEvals);
      writeInStats(averageEval);
    end

  end

  task :resources, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Resources Report")
    writeInStats("")

    allCreatedResources = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        resources = Document.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allCreatedResources.push(resources);
      end
    end

    writeInStats("")
    writeInStats("Created Resources")
    allCreatedResources.each do |createdResources|
      writeInStats(createdResources.count)
    end

    writeInStats("")
    writeInStats("Accumulative Created Resources")
    accumulativeResources = 0;
    allCreatedResources.each do |createdResources|
      accumulativeResources = accumulativeResources + createdResources.count
      writeInStats(accumulativeResources)
    end

    #Resources type
    writeInStats("")
    writeInStats("Type of Resources")
    resourcesReport = getResourcesByType(Document.all)

    resourcesReport.each do |resourceReport|
      writeInStats(resourceReport["resourceType"].to_s);
      writeInStats(resourceReport["percent"].to_s)
    end

  end

  task :users, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    writeInStats("")
    writeInStats("Users Report")
    writeInStats("")

    allUsers = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        users = User.where(:created_at => startDate..endDate)
        writeInStats(startDate.strftime("%B %Y"))
        allUsers.push(users);
      end
    end

    writeInStats("")
    writeInStats("Registered Users")
    allUsers.each do |users|
      writeInStats(users.count)
    end

    writeInStats("")
    writeInStats("Accumulative Registered Users")
    accumulativeUsers = 0;
    allUsers.each do |users|
      accumulativeUsers = accumulativeUsers + users.count
      writeInStats(accumulativeUsers)
    end

  end

  def getResourcesByType(resources)
    results = [];
    resourcesType = Hash.new;
    #resourcesType['file_content_type'] = [resources];

    resources.each do |resource|
      if resource.file_content_type
        if resourcesType[resource.file_content_type] == nil
          resourcesType[resource.file_content_type] = [];
        end
        resourcesType[resource.file_content_type].push(resource);
      end
    end

    resourcesType.each do |e|
      key = e[0]
      value = e[1]

      result = Hash.new;
      result["resourceType"] = key;
      result["percent"] = ((value.count/resources.count.to_f)*100).round(3);
      results.push(result);
    end

    results
  end

  def getViews(excursions)
    totalViews = 0;
    excursions.each do |excursion|
      totalViews = totalViews + excursion.visit_count
    end
    totalViews
  end

  def getAverage(array)
    accumulativeItem = 0;
    array.each do |item|
      if item == nil
        return nil
      end
       accumulativeItem = accumulativeItem + item;
    end
    return (accumulativeItem/array.count.to_f).round(2)
  end

  def writeInStats(line)
    write(line,STATS_FILE_PATH)
  end

end
