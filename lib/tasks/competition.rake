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

    #More vars
    awardedUsers = []

    #Test ids
    test_ids = Excursion.order("RAND(id)").map { |e| e.id.to_s }

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

        eUserId = e.author.user.id
        if awardedUsers.include? eUserId
          #This user is already a winner
          next
        end

        eCategories = getExcursionCategories(e)
        if eCategories.blank?
          puts "#####################################"
          puts "WARNING: Excursion without category"
          puts e
          puts "#####################################"
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

        prize = getAwardedPrizeForExcursion(eCategories,prizes)
        if prize != "NOPRIZE"
          prize = e
          awardedUsers.push(eUserId)
        end

        #Check finish
        unless hasPrizes(prizes)
          break;
        end

      else
        puts "#####################################"
        puts "WARNING: The following item does not include a ViSH ID, check the LOEP platform for details"
        puts item
        puts "#####################################"
      end
    end


    #Build final data
    fPrizes = []

    fFirstPrize = Hash.new
    fFirstPrize["Prize"] = "First best excursion"
    if !prizes["first"].nil?
      fFirstPrize["AuthorName"] = prizes["first"].author.user.name
      fFirstPrize["AuthorEmail"] = prizes["first"].author.user.email
      fFirstPrize["ExcursionName"] = prizes["first"].title
    end
    fPrizes.push(fFirstPrize)

    fSecondPrize = Hash.new
    fSecondPrize["Prize"] = "Second best excursion"
    if !prizes["second"].nil?
      fSecondPrize["AuthorName"] = prizes["second"].author.user.name
      fSecondPrize["AuthorEmail"] = prizes["second"].author.user.email
      fSecondPrize["ExcursionName"] = prizes["second"].title
    end
    fPrizes.push(fSecondPrize)

    fThirdPrize = Hash.new
    fThirdPrize["Prize"] = "Third best excursion"
    if !prizes["third"].nil?
      fThirdPrize["AuthorName"] = prizes["third"].author.user.name
      fThirdPrize["AuthorEmail"] = prizes["third"].author.user.email
      fThirdPrize["ExcursionName"] = prizes["third"].title
    end
    fPrizes.push(fThirdPrize)

    categories.each do |c|
      fC1Prize = Hash.new
      fC1Prize["Prize"] = "Best excursion. Category: " + c
      if !prizes[c]["first"].nil?
        fC1Prize["AuthorName"] = prizes[c]["first"].author.user.name
        fC1Prize["AuthorEmail"] = prizes[c]["first"].author.user.email
        fC1Prize["ExcursionName"] = prizes[c]["first"].title
      end
      fPrizes.push(fC1Prize)

      fC2Prize = Hash.new
      fC2Prize["Prize"] = "Second best excursion. Category: " + c
      if !prizes[c]["first"].nil?
        fC2Prize["AuthorName"] = prizes[c]["second"].author.user.name
        fC2Prize["AuthorEmail"] = prizes[c]["second"].author.user.email
        fC2Prize["ExcursionName"] = prizes[c]["second"].title
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
      return prizes[first.sample]["first"]
    end
    if !second.blank?
      return prizes[second.sample]["second"]
    end

    #Sorry, no prize for this excursion
    return "NOPRIZE"
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
      puts "Excursion Title:" + prize["ExcursionName"]
    end

    printSeparator
  end

  def printSeparator
    puts ""
    puts "--------------------------------------------------------------"
    puts ""
  end

end


