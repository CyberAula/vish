# encoding: utf-8
REPORT_FILE_PATH = "reports/recquiz.xlsx"

namespace :recquiz do

  #Usage
  #Development:   bundle exec rake recquiz:generateReport
  task :generateReport => :environment do |t,args|
    require "#{Rails.root}/lib/task_utils"
    require 'descriptive_statistics/safe'
    
    printTitle("Generating RecQuiz Report")

    startDate = DateTime.new(2019,3,1) #(year,month,day)
    endDate = DateTime.new(2020,6,30)
    firstDate = endDate
    lastDate = startDate

    products = {}

    ActiveRecord::Base.uncached do
      TrackingSystemEntry.where(:app_id=>"RecQuiz", :created_at => startDate..endDate).find_each batch_size: 1000 do |e|
        begin
          lastDate = e.created_at.to_date if e.created_at.to_date > lastDate
          firstDate = e.created_at.to_date if e.created_at.to_date < firstDate
          d = JSON(e["data"])
          unless d["actions"].blank?
            d["actions"].each do |k,v|
              case v["action_type"]
              when "CHANGE_SCREEN"
              when "TIME_RUNS_OUT"
              when "QUESTION_ANSWERED"
                pId = v["data"]["product_id"].to_i
                products[pId] = {"name": v["data"]["product_friendly_name"], "successes":0, "failures":0} if products[pId].nil?
                if v["data"]["success"]==="false"
                  products[pId][:failures] = products[pId][:failures]+1
                elsif v["data"]["success"]==="true"
                  products[pId][:successes] = products[pId][:successes]+1
                end
              else
                #Do nothing
              end
            end
          end
        rescue Exception => e
          puts "Exception: " + e.message
        end
      end
    end

    products = products.sort.to_h

    Axlsx::Package.new do |p|
      p.workbook.add_worksheet(:name => "RecQuiz Report") do |sheet|
        rows = []
        rows << ["RecQuiz Report"]
        rows << ["Period: " + startDate.strftime("%d/%m/%Y") + " - " + endDate.strftime("%d/%m/%Y") + " (" + ((endDate-startDate).to_i+1).to_s + " days)"]
        rows << ["Entries period: " + firstDate.strftime("%d/%m/%Y") + " - " + lastDate.strftime("%d/%m/%Y") + " (" + ((lastDate - firstDate).to_i+1).to_i.to_s + " days)"]
        rows << ["Product id","Product name","Generated questions","Successes","Failures","Success ratio"]
        rows << ["","","","","",""]
        rowIndex = rows.length

        rows += Array.new(products.length).map{|r|[]}
        products.each do |k,v|
          rows[rowIndex] = [k,v[:name],(v[:successes]+v[:failures]),v[:successes],v[:failures],(v[:successes]/(v[:successes]+v[:failures]).to_f*100).round(2)]
          rowIndex = rowIndex+1
        end
        
        rows.each do |row|
          sheet.add_row row
        end
      end

      p.serialize(REPORT_FILE_PATH)
    end

    puts("Task Finished. Results generated at " + REPORT_FILE_PATH)
  end

end