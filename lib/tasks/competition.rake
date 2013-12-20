# encoding: utf-8

namespace :competition do

  #Usage
  #Development:   bundle exec rake competition:build
  #In production: bundle exec rake competition:build RAILS_ENV=production
  task :build => :environment do

    puts "#####################################"
    puts "#####################################"
    puts "ViSH Competitions"
    puts "#####################################"
    puts "#####################################"

    #Prizes
    prizes = Hash.new

    #Best Excursions Prizes
    prizes["first"] = nil
    prizes["second"] = nil
    prizes["third"] = nil

    #Categories Prizes
    categories = getCategories
    categories.each do |c|
       prizes[c] = Hash.new
       prizes[c]["first"] = nil
       prizes[c]["second"] = nil
    end

    #[1] Get excursions
    excursions = []

    #Test ids
    # test_ids = Excursion.order("RAND(id)").map { |e| e.id.to_s }
    test_ids = [3,7,15,11,19,23,27,31,35,39,43,47,51,55,59,63,67,71,75,79,83,87,91,95,99,103,107,283,287,291,295,299,
303,307,311,315,319,323,327,331,335,339,343,347,351,355,359,363,367,371,375,379,383,387,391,395,399,403,407,411,415,
419,423,427,431,435,439,443,447,451,455,459,463,467,471,475,479,483,487,491,495,499,503,507]
    # e.tag_list = ["Maths","Physics","Chemistry","Geography","Biology","ComputerScience","EnvironmentalStudies","Engineering","Humanities","NaturalScience"].sample(2).join(",")
    test_categories = [["Maths","Physics"],["Maths"],["Geography"],["Geography"],["Geography"],["Geography","EnvironmentalStudies"]];


    loepItems = JSON(File.read("rankedIndex.json"))
    loepItems.each_with_index do |item,index|
      if item["vishId"]

        #Just for testing
        if index >= test_ids.length
          break
        end
        item["vishId"] = test_ids[index]
        #Testing end

        begin
          e = Excursion.find(item["vishId"].to_i)
        rescue
          puts "#####################################"
          puts "WARNING: The following item includes an invalid ViSH ID, check the LOEP platform for details"
          puts item
          puts "#####################################"
          next
        end

        #Test. Add categories
        # e.tag_list = ["Maths","Physics","Chemistry","Geography","Biology","ComputerScience","EnvironmentalStudies","Engineering","Humanities","NaturalScience"].sample(2).join(",")
        if index < test_categories.length
          e.tag_list = test_categories[index]
        end
        #Test end

        eCategories = getExcursionCategories(e)
        if eCategories.blank?
          puts "#####################################"
          puts "WARNING: Excursion without category"
          puts e
          puts "#####################################"
          next
        end

        # puts e.id
        excursions.push(e)
      else
        puts "#####################################"
        puts "WARNING: The following item does not include a ViSH ID, check the LOEP platform for details"
        puts item
        puts "#####################################"
      end
    end

    awardedUsers = []

    #First three prizes
    excursions.each do |e|

      eUserId = e.author.user.id
      if awardedUsers.include? eUserId
        #This user is already a winner
        next
      end

      #Check award for excursion
      if prizes["first"].nil?
        prizes["first"] = e
      elsif prizes["second"].nil?
        prizes["second"] = e
      elsif prizes["third"].nil?
        prizes["third"] = e
      end

      eCategories = getExcursionCategories(e)
      prize = getAwardedPrizeForExcursion(eCategories,prizes)
      if prize != "NOPRIZE"
        prizes[prize[0]][prize[1]] = e
        awardedUsers.push(eUserId)
      end

      #Check finish
      if !prizes["first"].nil? and !prizes["second"].nil? and !prizes["third"].nil?
        break
      end
    end
    excursions = excursions.reject { |e| awardedUsers.include? e.author.user.id }

    #2. Excursion - Awards matching

    while !isFinish(prizes,excursions)

      #3 Look for repeated users
      if awardedUsers != awardedUsers.uniq
        #One user with more than one prize...
        #Keep the better prize, remove the others
        awardedUsers.each do |userId|
          if awardedUsers.count(userId) > 1
            #repeated user

            #3.1 Select best user prize
            userPrize = getBestAwardedPrizeForUser(categories,userId,prizes)
            #3.2 Clean other prizes
            categories.each do |c|
              if !prizes[c]["first"].nil? and prizes[c]["first"].author.user.id == userId and (c != userPrize[0] and userPrize[1] != "first")
                prizes[c]["first"] = nil
              end
              if !prizes[c]["second"].nil? and prizes[c]["second"].author.user.id == userId and (c != userPrize[0] and userPrize[1] != "second")
                prizes[c]["second"] = nil
              end
            end
            #Clean LOs
            excursions = excursions.reject { |e| e.author.user.id ==  userId }
          end
        end
      end

      awardedUsersInNextRound = []

      excursions.each do |e|
        eCategories = getExcursionCategories(e)
        prize = getAwardedPrizeForExcursion(eCategories,prizes)
        if prize != "NOPRIZE"
          prizes[prize[0]][prize[1]] = e
          awardedUsers.push(e.author.user.id)
          awardedUsersInNextRound.push(e.author.user.id)
        end

        #Check finish
        if isFinish(prizes,excursions)
          break;
        end
      end

      if awardedUsersInNextRound.length === 0
        break
      end

    end


    #Build final data
    fPrizes = []

    fFirstPrize = Hash.new
    fFirstPrize["Prize"] = "First best excursion"
    if !prizes["first"].nil?
      fFirstPrize["AuthorName"] = prizes["first"].author.user.name
      fFirstPrize["AuthorEmail"] = prizes["first"].author.user.email
      fFirstPrize["AuthorID"] = prizes["first"].author.user.id
      fFirstPrize["ExcursionName"] = prizes["first"].title
      fFirstPrize["id"] = prizes["first"].id
    end
    fPrizes.push(fFirstPrize)

    fSecondPrize = Hash.new
    fSecondPrize["Prize"] = "Second best excursion"
    if !prizes["second"].nil?
      fSecondPrize["AuthorName"] = prizes["second"].author.user.name
      fSecondPrize["AuthorEmail"] = prizes["second"].author.user.email
      fSecondPrize["AuthorID"] = prizes["second"].author.user.id
      fSecondPrize["ExcursionName"] = prizes["second"].title
      fSecondPrize["id"] = prizes["second"].id
    end
    fPrizes.push(fSecondPrize)

    fThirdPrize = Hash.new
    fThirdPrize["Prize"] = "Third best excursion"
    if !prizes["third"].nil?
      fThirdPrize["AuthorName"] = prizes["third"].author.user.name
      fThirdPrize["AuthorEmail"] = prizes["third"].author.user.email
      fThirdPrize["AuthorID"] = prizes["third"].author.user.id
      fThirdPrize["ExcursionName"] = prizes["third"].title
      fThirdPrize["id"] = prizes["third"].id
    end
    fPrizes.push(fThirdPrize)

    categories.each do |c|
      fC1Prize = Hash.new
      fC1Prize["Prize"] = "Best excursion. Category: " + c
      if !prizes[c]["first"].nil?
        fC1Prize["AuthorName"] = prizes[c]["first"].author.user.name
        fC1Prize["AuthorEmail"] = prizes[c]["first"].author.user.email
        fC1Prize["AuthorID"] = prizes[c]["first"].author.user.id
        fC1Prize["ExcursionName"] = prizes[c]["first"].title
        fC1Prize["id"] = prizes[c]["first"].id
      end
      fPrizes.push(fC1Prize)

      fC2Prize = Hash.new
      fC2Prize["Prize"] = "Second best excursion. Category: " + c
      if !prizes[c]["second"].nil?
        fC2Prize["AuthorName"] = prizes[c]["second"].author.user.name
        fC2Prize["AuthorEmail"] = prizes[c]["second"].author.user.email
        fC2Prize["AuthorID"] = prizes[c]["second"].author.user.id
        fC2Prize["ExcursionName"] = prizes[c]["second"].title
        fC2Prize["id"] = prizes[c]["second"].id
      end
      fPrizes.push(fC2Prize)
     
    end

    printSeparator
    fPrizes.each do |prize|
      printPrize(prize)
    end
    printSeparator

    puts "#####################################"
    puts "Task Finished"
    puts "#####################################"
  end


  def getCategories
    return ["Maths","Physics","Chemistry","Geography","Biology","ComputerScience","EnvironmentalStudies","Engineering","Humanities","NaturalScience"]
  end

  def getExcursionCategories(e)
    e.tag_list.reject{ |c| !getCategories.include? c }
  end

  def getAwardedPrizeForExcursion(eCategories,prizes)
    first = []
    second = []

    eCategories.each do |c|
      if prizes[c]["first"].nil?
        first.push(c)
        next
      end
      if prizes[c]["second"].nil?
        second.push(c)
        next
      end
    end

    if !first.blank?
      return[first.sample,"first"]
    end
    if !second.blank?
      return[second.sample,"second"]
    end

    #Sorry, no prize for this excursion
    return "NOPRIZE"
  end

  def getBestAwardedPrizeForUser(categories,userId,prizes)
    first = []
    second = []

    categories.each do |c|
      if !prizes[c]["first"].nil? and prizes[c]["first"].author.user.id == userId
        first.push(c)
        next
      end
      if !prizes[c]["second"].nil? and prizes[c]["second"].author.user.id == userId
        second.push(c)
        next
      end
    end

    if !first.blank?
      return[first.sample,"first"]
    end
    if !second.blank?
      return[second.sample,"second"]
    end

    #Sorry, no prize for this user
    return "NOPRIZE?"
  end

  def hasPrizes(prizes)
    if prizes["first"].nil? or prizes["second"].nil? or prizes["third"].nil?
      return true
    end
    getCategories.each do |c|
      if prizes[c]["first"].nil? or prizes[c]["second"].nil?
        return true
      end
    end
    return false
  end

  def isFinish(prizes,excursions)
    if excursions.length == 0
      return true
    end
    return !hasPrizes(prizes)
  end

  def printExcursion(e)
    if e.nil?
      puts "nil"
      return
    end
    user = e.author.user
    puts "Excursion Title:" + e.title
    puts "Excursion id:" + e.id
    puts "Author name: " + user.name
    puts "Author email: " + user.email
    printSeparator
  end

  def printPrize(prize)
    if prize["Prize"].is_a? String
      puts prize["Prize"]
    end

    if !prize["ExcursionName"].nil?
      puts "Author name: " + prize["AuthorName"]
      puts "Author email: " + prize["AuthorEmail"]
      puts "Author ID: " + prize["AuthorID"].to_s
      puts "Excursion Title: " + prize["ExcursionName"]
      puts "Excursion ID: " + prize["id"].to_s
    end

    printSeparator
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end


