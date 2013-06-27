# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.
require 'builder'

class Excursion < ActiveRecord::Base
  include SocialStream::Models::Object
  has_many :excursion_contributors, :dependent => :destroy
  has_many :contributors, :class_name => "Actor", :through => :excursion_contributors

  validates_presence_of :json
  after_save :parse_for_meta
  before_save :fix_relation_ids_drafts
  after_destroy :remove_scorm
  after_destroy :remove_pdf

  define_index do
    activity_object_index

    indexes excursion_type
    has slide_count
    has draft
    has activity_object.like_count, :as => :like_count
    has activity_object.visit_count, :as => :visit_count
  end

  def to_json(options=nil)
    json
  end

  def to_scorm(controller)
    if self.scorm_needs_generate
      require 'zip/zip'
      require 'zip/zipfilesystem'  
      t = File.open("#{Rails.root}/public/scorm/excursions/#{self.id}.zip", 'w')
      Zip::ZipOutputStream.open(t.path) do |zos|
        xml_manifest = self.generate_scorm_manifest
        zos.put_next_entry("imsmanifest.xml")
        zos.print xml_manifest.target!()

        zos.put_next_entry("excursion.html")
        zos.print controller.render_to_string "show.scorm.erb", :locals => {:excursion=>self}, :layout => false  

        self.update_column(:scorm_timestamp, Time.now)
      end    
      t.close
    end
  end

  def scorm_needs_generate
    if self.scorm_timestamp.nil? or self.updated_at > self.scorm_timestamp or !File.exist?("#{Rails.root}/public/scorm/excursions/#{self.id}.zip")
      return true;
    else
      return false;
    end
  end

  def generate_scorm_manifest
    ejson = JSON(self.json)
    myxml = ::Builder::XmlMarkup.new(:indent => 2)
    myxml.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    myxml.manifest("identifier"=>"VISH_VIRTUAL_EXCURSION_" + self.id.to_s,
      "version"=>"1.0", 
      "xsi:schemaLocation"=>"http://www.imsglobal.org/xsd/imscp_v1p1.xsd http://www.adlnet.org/xsd/adlcp_v1p3.xsd http://www.adlnet.org/xsd/adlnav_v1p3.xsd http://www.adlnet.org/xsd/adlseq_v1p3.xsd http://www.imsglobal.org/xsd/imsss_v1p0.xsd http://ltsc.ieee.org/xsd/LOM/lom.xsd",
      "xmlns:adlcp"=>"http://www.adlnet.org/xsd/adlcp_v1p3",
      "xmlns:xsi"=>"http://www.w3.org/2001/XMLSchema-instance",
      "xmlns"=>"http://www.imsglobal.org/xsd/imscp_v1p1",
      "xmlns:imsss"=>"http://www.imsglobal.org/xsd/imsss",
      "xmlns:lom"=>"http://ltsc.ieee.org/xsd/LOM/lom.xsd" ) do


      myxml.metadata() do
        myxml.schema("ADL SCORM");
        myxml.schemaversion("CAM 1.3");

        myxml.lom do
          myxml.general do
            myxml.identifier("VISH_VIRTUAL_EXCURSION_"+ self.id.to_s);
            myxml.title do
              myxml.langstring(self.title);
            end
            myxml.language(ejson["language"]);
            myxml.description do
              myxml.langstring(self.title + ". A Virtual Excursion provided by http://vishub.org.");
            end
            self.tags.each do |tag|
              myxml.keyword do
                myxml.langstring(tag.name.to_s);
              end
            end
            myxml.structure do
              myxml.source do
                myxml.langstring("LOMv1.0");
              end
              myxml.value do
                myxml.langstring("hierarchical");
              end
            end
            myxml.aggregationlevel do
              myxml.source do
                myxml.langstring("LOMv1.0");
              end
              myxml.value do
                myxml.langstring("4");
              end
            end
          end

          myxml.lifecycle do
            myxml.version do
              myxml.langstring("1.0");
            end
            myxml.status do
              myxml.source do
                myxml.langstring("LOMv1.0");
              end
              myxml.value do
                myxml.langstring("final");
              end
            end
            myxml.contribute do
              myxml.role do
                myxml.source do
                  myxml.langstring("LOMv1.0");
                end
                myxml.value do
                  myxml.langstring("author");
                end
              end
              myxml.centity do
                myxml.vcard("begin:vcard\n n:"+self.author.name+"\n fn:\n end:vcard");
              end
              myxml.date do
                myxml.datetime(self.updated_at.strftime("%d/%m/%y"));
              end
            end
          end

          myxml.technical do
            myxml.format("text/html")
            myxml.location("http://vishub.org/excursions/"+self.id.to_s);
            myxml.requirement do
              myxml.type do
                myxml.source do
                  myxml.langstring("LOMv1.0")
                end
                myxml.value do
                  myxml.langstring("browser")
                end
              end
              myxml.name do
                myxml.source do
                  myxml.langstring("LOMv1.0")
                end
                myxml.value do
                  myxml.langstring("any")
                end
              end
            end
            myxml.otherplatformrequirements do
              myxml.langstring("HTML5-compliant web browser")
            end
          end

          myxml.educational do
            myxml.interactivitytype do
              myxml.source do
                myxml.langstring("LOMv1.0")
              end
              myxml.value do
                myxml.langstring("mixed")
              end
            end
            myxml.learningresourcetype do
              myxml.source do
                myxml.langstring("LOMv1.0")
              end
              myxml.value do
                myxml.langstring("slide")
              end
            end
            myxml.interactivitylevel do
              myxml.source do
                myxml.langstring("LOMv1.0")
              end
              myxml.value do
                myxml.langstring("very high")
              end
            end
            myxml.intendedenduserrole do
              myxml.source do
                myxml.langstring("LOMv1.0")
              end
              myxml.value do
                myxml.langstring("learner")
              end
            end
            myxml.typicalagerange do
              myxml.langstring(self.age_min.to_s + "-" + self.age_max.to_s)
            end
            myxml.difficulty do
              myxml.source do
                myxml.langstring("LOMv1.0")
              end
              myxml.value do
                myxml.langstring("medium")
              end
            end
            myxml.typicallearningtime do
              #Inferred
              # 1 min per slide
              inferredTPL = (self.slide_count * 1).to_s
              myxml.duration("PT"+inferredTPL+"M0S")
            end
            myxml.description do
              myxml.langstring(ejson["educational_objectives"])
            end
            myxml.language(ejson["language"])
          end
        end
      end


      myxml.organizations('default'=>"ViSH",'structure'=>"hierarchical") do
        myxml.organization('identifier'=>"ViSH") do
          myxml.title("Virtual Science Hub");
          myxml.metadata() do
            myxml.schema("ADL SCORM");
            myxml.schemaversion("CAM 1.3");
            myxml.lom do
              myxml.general do
                myxml.identifier("ViSH");
                myxml.title do
                  myxml.langstring("Virtual Science Hub");
                end
                myxml.description do
                  myxml.langstring("Virtual Science Hub. http://vishub.org.");
                end
              end
            end
          end
          myxml.item('identifier'=>"VIRTUAL_EXCURSION_" + self.id.to_s,'identifierref'=>"VIRTUAL_EXCURSION_" + self.id.to_s + "_RESOURCE") do
            myxml.title(self.title);
          end
        end
      end


      myxml.resources do         
        myxml.resource('identifier'=>"VIRTUAL_EXCURSION_" + self.id.to_s + "_RESOURCE", 'type'=>"webcontent", 'href'=>"excursion.html", 'adlcp:scormtype'=>"sco") do
          myxml.file('href'=> "excursion.html")
        end
      end

    end    

    return myxml
  end

  def remove_scorm
    if File.exist?("#{Rails.root}/public/scorm/excursions/#{self.id}.zip")
      File.delete("#{Rails.root}/public/scorm/excursions/#{self.id}.zip") 
    end
  end

  def to_pdf(controller)
    if self.pdf_needs_generate
      slidesQuantity = generate_thumbnails(controller)
      if slidesQuantity > 0
        pdfFolder = "#{Rails.root}/public/pdf/excursions/#{self.id}"

        #Generate PDF
        pdf = File.open(pdfFolder+"/#{self.id}.pdf", 'w')

        require 'RMagick'
        images = []
        slidesQuantity.times do |num|
          images.push(pdfFolder + "/#{self.id}_#{num+1}.png");
        end
        pdf_image_list = ::Magick::ImageList.new
        pdf_image_list.read(*images)
        pdf_image_list.write(pdfFolder + "/#{self.id}.pdf")
        pdf.close

        self.update_column(:pdf_timestamp, Time.now)
      end
    end
  end

  def generate_thumbnails(controller)
    begin
      #Create folder if not exists
      pdfFolder = "#{Rails.root}/public/pdf/excursions/#{self.id}"
      Dir.mkdir(pdfFolder) unless File.exists?(pdfFolder)

      require 'selenium-webdriver'
      Selenium::WebDriver::Chrome.path = "/usr/lib/chromium-browser/chromium-browser"
      driver = Selenium::WebDriver.for :chrome

      # Testing
      # excursion_url = 'http://vishub.org/excursions/55.full'
      
      excursion_url = controller.url_for( :controller => 'excursions', :action => 'show', :format => 'full', :id=>self.id);
      # driver.navigate.to excursion_url
      driver.get excursion_url

      #Specify screenshots dimensions
      width = 775;
      height = 1042;
      driver.execute_script %Q{ window.resizeTo(#{width}, #{height}); }

      #Hide fullscreen button
      driver.execute_script %Q{ $("#page-fullscreen").hide(); }
      #Disable non-iframe alerts
      driver.execute_script %Q{ window.alert = function(){}; }

      #Get slidesQuantity
      slidesQuantity = driver.execute_script %Q{ 
        return VISH.Slides.getSlidesQuantity();
      }

      #Take a screenshot of each slide
      slidesQuantity.times do |num|
        driver.execute_script %Q{
          VISH.Slides.goToSlide(#{num+1});
        }
        driver.execute_script %Q{ 
          $("article.current").css("display","block");
          $("article").not(".current").css("display","none");
        }

        Selenium::WebDriver::Wait.new(:timeout => 30).until { 
          # TODO:// VISH.SlideManager.isSlideLoaded()
          driver.execute_script("return true")
        }
        #Wait a constant period
        sleep 1.5;

        #Remove alert (if is present)
        driver.switch_to.alert.accept rescue Selenium::WebDriver::Error::NoAlertOpenError

        driver.save_screenshot(pdfFolder + "/#{self.id}_#{num+1}.png")
      end

      driver.quit
      return slidesQuantity

    rescue Exception => e
      begin
        driver.quit
      rescue
      end
      puts e.message
      return -1;
    end
  end

  def pdf_needs_generate
    if self.pdf_timestamp.nil? or self.updated_at > self.pdf_timestamp or !File.exist?("#{Rails.root}/public/pdf/excursions/#{self.id}/#{self.id}.pdf")
      return true;
    else
      return false;
    end
  end

  def remove_pdf
    if File.exist?("#{Rails.root}/public/pdf/excursions/#{self.id}")
      FileUtils.rm_rf("#{Rails.root}/public/pdf/excursions/#{self.id}") 
    end
  end

  def clone_for sbj
    return nil if sbj.blank?
    e=Excursion.new
    e.author=sbj
    e.owner=sbj
    e.user_author=sbj.user.actor
    e.json = self.json
    e.contributors=self.contributors.push(self.author)
    e.contributors.uniq!
    e.contributors.delete(sbj)
    e.draft=true
    e.save!
    e
  end

  #method used to return json objects to the recommendation in the last slide
  def reduced_json(controller)
      excursion_url = controller.url_for( :controller => 'excursions', :action => 'show', :id=>self.id)
      
      { :id => id,
        :url => excursion_url,
        :title => title,
        :author => author.name,
        :description => description,
        :image => thumbnail_url ? thumbnail_url : "/assets/logos/original/excursion-00.png",
        :views => visit_count,
        :favourites => like_count,
        :number_of_slides => slide_count
      }
  end

  def evaluations
    ExcursionEvaluation.where(:excursion_id => self.id)
  end

  def averageEvaluation
    evaluations = []
    if self.evaluations.length > 0
      6.times do |ind|
        evaluations.push(ExcursionEvaluation.average("answer_"+ind.to_s, :conditions=>["excursion_id=?", self.id]).to_f.round(2))
      end
    else
      evaluations = [0,0,0,0,0,0];
    end
    evaluations
  end


  private

  def parse_for_meta
    parsed_json = JSON(json)
    activity_object.title = parsed_json["title"]
    activity_object.description = parsed_json["description"]
    activity_object.tag_list = parsed_json["tags"]
    begin
      ageRange = parsed_json["age_range"]
      activity_object.age_min = ageRange.split("-")[0].delete(' ')
      activity_object.age_max = ageRange.split("-")[1].delete(' ')
    rescue
    end
    
    activity_object.save!

    parsed_json["id"] = activity_object.id.to_s
    parsed_json["author"] = author.name
    self.update_column :json, parsed_json.to_json
    self.update_column :excursion_type, parsed_json["type"]
    self.update_column :slide_count, parsed_json["slides"].size
    self.update_column :thumbnail_url, parsed_json["avatar"]
  end

  def fix_relation_ids_drafts
    if self.draft
      activity_object.relation_ids=[Relation::Private.instance.id]
    else
      activity_object.relation_ids=[Relation::Public.instance.id]
    end
  end

end
