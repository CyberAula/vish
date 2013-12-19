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

    # excursions = ActivityObject.tagged_with("ViSHCompetition2013").map(&:object).select{|a| a.class==Excursion && a.draft == false}
    
    loepItems = JSON(File.read("rankedIndex.json"))

    loepItems.each do |item|
      if item["vishId"]
        puts item["vishId"]
      else
        puts "#####################################"
        puts "WARNING: The following item does not include a ViSH ID, check the LOEP platform for details"
        puts item
        puts "#####################################"
      end
    end

    puts "#####################################"
    puts "Task Finished"
    puts "#####################################"
  end


  def getCategories
    return ["Maths","Physics","Chemistry","Geography","Biology","ComputerScience","EnvironmentalStudies","Engineering","Humanities","NaturalScience"]
  end

end


