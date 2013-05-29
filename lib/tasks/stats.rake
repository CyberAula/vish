
STATS_FILE_PATH = "public/";


namespace :stats do

  task :prepare do
    puts "PREPARE"
    system "rm " + STATS_FILE_PATH + "stats.txt"
    system "touch " + STATS_FILE_PATH + "stats.txt"
    write("ViSH Stats Report")
  end

  task :all => :environment do
    Rake::Task["stats:prepare"].invoke
    Rake::Task["stats:excursions"].invoke(false)
    Rake::Task["stats:resources"].invoke(false)
    Rake::Task["stats:users"].invoke(false)
  end

  task :excursions, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    write("")
    write("Excursions Report")
    write("")

    allCreatedExcursions = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        excursions = Excursion.where(:created_at => startDate..endDate)
        write(startDate.strftime("%B %Y"))
        allCreatedExcursions.push(excursions);
      end
    end

    write("")
    write("Total Views")

    allTotalViews = [];
    allCreatedExcursions.each do |excursions|
      totalViews = getViews(excursions)
      allTotalViews.push(totalViews);
      write(totalViews)
    end

    write("")
    write("Total Accumulative Views")
    accumulativeViews = 0;
    allTotalViews.each do |totalViews|
      accumulativeViews = accumulativeViews + totalViews
      write(accumulativeViews)
    end

    write("")
    write("Created Excursions")
    allCreatedExcursions.each do |createdExcursions|
      write(createdExcursions.count)
    end

    write("")
    write("Accumulative Created Excursions")
    accumulativeExcursions = 0;
    allCreatedExcursions.each do |createdExcursions|
      accumulativeExcursions = accumulativeExcursions + createdExcursions.count
      write(accumulativeExcursions)
    end

    # Evaluations
    evaluations = [];
    6.times do |index|
      evaluations.push(ExcursionEvaluation.average("answer_"+index.to_s).to_f.round(2));
    end
    evaluationsAverage = getAverage(evaluations)
 
    write("")
    write("Evaluations: Average")
    write("Content")
    write("Design")
    write("Motivation")
    write("Engagement")
    write("Interdisciplinary")
    write("Use again")
    write("All")

    evaluations.each do |evaluation|
      write(evaluation);
    end
    write(evaluationsAverage);


    # Evaluations evolution
    write("")
    write("Evaluations: Evolution")
    write("[Content,Design,Motivation,Engagement,Interdisciplinary,Use again]")

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
      write(averageEval)
    end

    write("")
    write("Average of all evaluations")
    averageEvalsList.each do |averageEvals|
      averageEval = getAverage(averageEvals);
      write(averageEval);
    end

  end

  task :resources, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    write("")
    write("Resources Report")
    write("")

    allCreatedResources = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        resources = Document.where(:created_at => startDate..endDate)
        write(startDate.strftime("%B %Y"))
        allCreatedResources.push(resources);
      end
    end

    write("")
    write("Created Resources")
    allCreatedResources.each do |createdResources|
      write(createdResources.count)
    end

    write("")
    write("Accumulative Created Resources")
    accumulativeResources = 0;
    allCreatedResources.each do |createdResources|
      accumulativeResources = accumulativeResources + createdResources.count
      write(accumulativeResources)
    end

    #Resources type
    write("")
    write("Type of Resources")
    resourcesReport = getResourcesByType(Document.all)

    resourcesReport.each do |resourceReport|
      write(resourceReport["resourceType"].to_s);
      write(resourceReport["percent"].to_s)
    end

  end

  task :users, [:prepare] => :environment do |t,args|
    args.with_defaults(:prepare => true)

    if args.prepare
      Rake::Task["stats:prepare"].invoke
    end

    write("")
    write("Users Report")
    write("")

    allUsers = [];
    for year in 2012..2014
      12.times do |index|
        month = index+1;
        # date = DateTime.new(params[:year],params[:month],params[:day]);
        startDate = DateTime.new(year,month,1)
        endDate = startDate.next_month;
        users = User.where(:created_at => startDate..endDate)
        write(startDate.strftime("%B %Y"))
        allUsers.push(users);
      end
    end

    write("")
    write("Registered Users")
    allUsers.each do |users|
      write(users.count)
    end

    write("")
    write("Accumulative Registered Users")
    accumulativeUsers = 0;
    allUsers.each do |users|
      accumulativeUsers = accumulativeUsers + users.count
      write(accumulativeUsers)
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
  
  def write(line)
    if line==nil
      line = "nil"
    end
    puts line.to_s

    # Create a new file and write to it  
    File.open(STATS_FILE_PATH+'stats.txt', 'a') do |f| 
      f.puts  line.to_s + "\n"
    end
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

end
