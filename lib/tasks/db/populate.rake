#
# You've got to love rake here:
# to patch social_stream's populate.rake, you can name this file anything but populate.rake
#

namespace :db do

  #override SocialStream code which calls 'db:populate:reload'
  task(:populate).clear.enhance(['db:populate:vish_reload'])


  namespace :populate do

    desc "Reload populate data"
    task :vish_reload => [ 'db:reset', :precreate, :create ]
    
    # Clear existing tasks (Social Stream tasks)
    task(:create_ties).prerequisites.clear
    task(:create_ties).clear
    %w( db:seed create:groups ).each do |t|
      task(:create).prerequisites.delete(t)
    end

    # User 12 logos
    ENV['LOGOS_TOTAL'] = 12.to_s

    desc "Create populate data for ViSH"
    task :precreate => [ 'create:roles', 'create:licenses' ]
    task :create => [ 'create:occupations', 'create:excursions', 'create:current_site', 'create:admin', 'create:demo_user' ]
    #Social Stream create task
    #task :create => [ :read_environment, :create_users, :create_ties, :create_posts, :create_messages, :create_excursions, :create_documents, :create_avatars ]


    namespace :create do
      
      desc "Create Ties as follows and rejects only"
      task :ties do
        puts 'Follows population'
        ties_start = Time.now

        @available_actors.each do |a|
          actors = @available_actors.dup - Array(a)
          relations = [ Relation::Follow.instance, Relation::Reject.instance ]
          break if actors.size==0
          Forgery::Basic.number(:at_most => actors.size).times do
            actor = actors.delete_at((rand * actors.size).to_i)
            contact = a.contact_to!(actor)
            contact.user_author = a.user_author if a.subject_type != "User"
            contact.relation_ids = Array(Forgery::Extensions::Array.new(relations).random.id) unless a==actor
          end
        end

        ties_end = Time.now
        puts '   -> ' +  (ties_end - ties_start).round(4).to_s + 's'
      end

      desc "Assign an occupation to users"
      task :occupations do
        puts 'Occupation population'
        occupations_start = Time.now

        User.all.each do |u|
          u.update_attributes(:occupation => rand(Occupation.size))
        end

        occupations_end = Time.now
        puts '   -> ' +  (occupations_end - occupations_start).round(4).to_s + 's'
      end

      desc "Populate excursions to the database"
      task :excursions do
        puts 'Excursion population'
        excursions_start = Time.now
        @slide_id=0
        @available_actors = Actor.all

        # Got Random images from lorempixel.com for development porpuses
        @sample_images_variant = %w{
          http://lorempixel.com/1024/768/
          http://lorempixel.com/1440/900/abstract/
          http://lorempixel.com/1024/768/nature/
          http://lorempixel.com/1440/900/animals/
          http://lorempixel.com/1024/768/transport/
          http://lorempixel.com/1440/900/cats/
          http://lorempixel.com/1024/768/fashion/
          http://lorempixel.com/1024/768/technics/
          http://lorempixel.com/1440/900/business/
          http://lorempixel.com/1024/768/sports/
          http://lorempixel.com/1024/768/city/
        }


        # Some sample science images in the public domain. Used Google Images option to public domain
        @sample_images = %w{
          http://libreshot.com/wp-content/uploads/2015/01/sad-puppy.jpg
          http://upload.wikimedia.org/wikipedia/commons/2/27/Wolf_Yawns_(5302403718).jpg
          https://farm1.staticflickr.com/210/464791157_452d6fef46_o.jpg
          http://res.freestockphotos.biz/pictures/17/17615-a-beautiful-sunset-pv.jpg
          https://farm6.staticflickr.com/5497/9170132090_09ecd3c087_z.jpg
          http://upload.wikimedia.org/wikipedia/commons/thumb/6/63/Beautiful_red_apple.jpg/800px-Beautiful_red_apple.jpg
        }

        def generate_slide
          img_right = rand() > 0.5
          slide_id = "article#{@slide_id+=1}"

          { # Slide N
            :id => slide_id,
            :template => 't1',
            :type => 'standard',
            :elements => [
              { # Element 1
                :type => 'text',
                :id => slide_id + "_zone1",
                :areaid => 'header',
                :body => Forgery::LoremIpsum.words(1+rand(4),:random => true)
              },
              { # Element 2
                :type => ( img_right ? 'image' : 'text' ),
                :id => slide_id + "_zone2",
                :areaid => 'right',
                :body => ( img_right ? @sample_images[rand(@sample_images.size)] : Forgery::LoremIpsum.paragraph(:random => true) )
              },
              { # Element 3
                :type => ( img_right ? 'text' : 'image' ),
                :id => slide_id + "_zone3",
                :areaid => 'left',
                :body => ( img_right ? Forgery::LoremIpsum.paragraph(:random => true) : @sample_images[rand(@sample_images.size)] )
              }
            ]
          }
        end

        500.times do
          updated = Time.at(rand(Time.now.to_i))
          author = @available_actors[rand(@available_actors.size)]
          owner  = author
          user_author =  ( author.subject_type == "User" ? author : author.user_author )

          if user_author == nil
            user_author = author
          end

          e = Excursion.create! :json => {  :title => "kike#{Forgery::LoremIpsum.words(1+rand(4),:random => true)}",
                                            :description => "#{Forgery::LoremIpsum.paragraph(:random => true)}",
                                            :author => author.name,
                                            :avatar => @sample_images[rand(@sample_images.size)],
                                            :slides => Array.new(1+rand(9)).map{ generate_slide }
                                         }.to_json,
                                :created_at => Time.at(rand(updated.to_i)),
                                :updated_at => updated,
                                :author_id  => author.id,
                                :owner_id   => owner.id,
                                :user_author_id => user_author.id,
                              :tag_list => ["Maths","Physics","Chemistry","Geography","Biology","ComputerScience","EnvironmentalStudies","Engineering","Humanities","NaturalScience"].sample(2).join(",")
          e.save!
        end

        #create one draft per actor
        @available_actors.each do |a|
          updated = Time.at(rand(Time.now.to_i))
          author = a
          owner  = author
          user_author =  ( author.subject_type == "User" ? author : author.user_author )

          if user_author ==nil
            user_author = author
          end

          e = Excursion.create! :json => {  :title => "#{Forgery::LoremIpsum.words(1+rand(4),:random => true)}",
                                            :description => "Description: #{Forgery::LoremIpsum.paragraph(:random => true)}",
                                            :author => author.name,
                                            :avatar => @sample_images[rand(@sample_images.size)],
                                            :slides => Array.new(1+rand(9)).map{ generate_slide }
                                         }.to_json,
                                :created_at => Time.at(rand(updated.to_i)),
                                :updated_at => updated,
                                :author_id  => author.id,
                                :owner_id   => owner.id,
                                :user_author_id => user_author.id,
                                :draft => true
          e.save!
        end

        excursions_end = Time.now
        puts '   -> ' +  (excursions_end - excursions_start).round(4).to_s + 's'
      end

      desc "Create excursion comments"
      task :comments do
        puts 'Excursion comments population'
        comments_start = Time.now

        def fake_comment(activity)
          Comment.new(:owner_id => Actor.normalize_id(activity.receiver), :_activity_parent_id => activity.id, :text => "Hola")
        end

        Excursion.all.each do |e|
          fake_comment(e.post_activity)
        end

        comments_end = Time.now
        puts '   -> ' +  (comments_end - comments_start).round(4).to_s + 's'
      end

      desc "Create current site"
      task :current_site do
        puts 'Current site population'
        current_site_start = Time.now

        Site.current.name = "ViSH"
        Site.current.email = Vish::Application.config.APP_CONFIG["main_mail"]
        Site.current.activity_object.relation_ids = [Relation::Private.instance.id]
        Site.current.activity_object.scope = 1 #private
        Site.current.actor!.update_attribute :slug, 'vish'
        Site.current.config["tmpCounter"] = 1
        Site.current.save!

        current_site_end = Time.now
        puts '   -> ' +  (current_site_end - current_site_start).round(4).to_s + 's'
      end

      #Usage
      #Development:   bundle exec rake db:populate:create:admin
      #In production: bundle exec rake db:populate:create:admin RAILS_ENV=production
      desc "Create ViSH Admin"
      task :admin => :environment do
        puts 'Creating admin user'

        # Create admin user if not present
        admin = User.find_by_slug('admin')
        if admin.blank?
          admin = User.new
        end

        admin.name = 'ViSH Admin'
        admin.email = 'admin@vishub.org'
        admin.password = 'demonstration'
        admin.password_confirmation = admin.password
        admin.save!
        admin.actor!.update_attribute :slug, 'admin'

        #Make the user 'admin' the administrator of the ViSH Site
        admin.actor!.make_me_admin

        puts "Admin created with email: " + admin.email + " and password: " + admin.password
      end

      #Usage
      #Development:   bundle exec rake db:populate:create:demo_user
      #In production: bundle exec rake db:populate:create:demo_user RAILS_ENV=production
      desc "Create ViSH demo user"
      task :demo_user => :environment do
        puts 'Creating demo user'

        # Create demo user if not present
        demo = User.find_by_slug('demo')
        if demo.blank?
          demo = User.new
        end

        # If present, ensure that has the appropiate data
        demo.name = 'Demo'
        demo.email = 'demo@vishub.org'
        demo.password = 'demonstration'
        demo.password_confirmation = demo.password
        demo.save!
        demo.actor!.update_attribute :slug, 'demo'
        demo.actor!.degrade

        puts "Demo user created with email: " + demo.email + " and password: " + demo.password
      end

      #Usage
      #Development:   bundle exec rake db:populate:create:roles
      #In production: bundle exec rake db:populate:create:roles RAILS_ENV=production
      desc "Create Roles"
      task :roles => :environment do
        SocialStream::Population.task 'Roles population' do
          roles = [
            { name: "Admin", value:9 },
            { name: "User", value:1 },
            { name: "PremiumUser", value:1 },
            { name: "PrivateStudent", value:1 }
          ]
          roles.each do |role|
            r = Role.find_by_name(role[:name])
            if r.nil?
              Role.create!  :name  => role[:name], :value => role[:value]
            end
          end
        end
      end

      #Usage
      #Development:   bundle exec rake db:populate:create:licenses
      #In production: bundle exec rake db:populate:create:licenses RAILS_ENV=production
      desc "Create Licenses"
      task :licenses => :environment do
        SocialStream::Population.task 'Licenses population' do
          licenseKeys = []
          licenseKeys.push("public")
          licenseKeys.push("cc-by")
          licenseKeys.push("cc-by-sa")
          licenseKeys.push("cc-by-nd")
          licenseKeys.push("cc-by-nc")
          licenseKeys.push("cc-by-nc-sa")
          licenseKeys.push("cc-by-nc-nd")
          licenseKeys.push("other")
          licenseKeys.push("private") #none (All rights reserved)

          licenseKeys.each do |key|
            if License.find_by_key(key).nil?
              l = License.new
              l.key = key
              l.save!
            end
          end
        end
      end

    end
  end

  #Usage
  #Development:   bundle exec rake db:anonymize[false]
  desc "Anonymize database for delivering"
  task :anonymize, [:interactions] => :environment do |t,args|
    printTitle("Anonymizing database")
    args.with_defaults(:interactions => false)

    User.record_timestamps=false
    Actor.record_timestamps=false
    Profile.record_timestamps=false
    Comment.record_timestamps=false
    ActivityObject.record_timestamps=false

    # popularTags = ActivityObject.tag_counts(:order => "count desc").first(50)

    User.all.each do |u|
      u.name = Faker::Name.name[0,30]
      u.password = "demonstration"
      u.slug = u.name.to_url #Create slug using stringex gem
      unless User.find_by_slug(u.slug).nil?
        u.slug = u.slug + "-" + u.id.to_s
      end
      u.email = u.slug + "@vishub.org"
      u.current_sign_in_ip = nil
      u.last_sign_in_ip = nil
      u.logo = nil
      u.occupation = nil
      # u.tag_list = popularTags.sample(3).map{|tag| tag.name}
      u.save(:validate => false)

      #User profile
      up = u.profile
      unless up.description.nil?
        up.description = Faker::Lorem.sentence(20, true)
      end
      unless up.organization.nil?
        up.organization = Faker::Company.name[0,30]
      end
      unless up.city.nil?
        up.city = Faker::Address.city[0,30]
      end
      unless up.country.nil?
        up.country = Faker::Address.country[0,30]
      end
      unless up.website.nil?
        up.website = Faker::Internet.url[0,30]
      end
      
      up.birthday = nil
      up.phone = nil
      up.mobile = nil
      up.fax = nil
      up.address = nil
      up.zipcode = nil
      up.province = nil
      up.prefix_key = nil
      up.experience = nil
      up.skype = nil

      up.save(:validate => false)
    end

    #Create demo user
    user = User.all.select{|u| !u.admin? && Excursion.authored_by(u).length>0 && u.follower_count>0}.sort{|ub,ua| ua.ranking<=>ub.ranking}.first
    if user.nil?
      user = User.all.reject{|u| u.admin?}.sample
    end

    unless user.nil?
      user.email = "demo@vishub.org"
      user.password = "demonstration"
      user.save(:validate => false)
      printTitle("Demo user created with email: '"+user.email+"' and password '"+user.password+"'.")
    end

    #Create admin user
    admin_user = User.all.select{|u| u.admin?}.first
    if admin_user.nil?
      #Create admin
      Rake::Task["db:populate:create:admin"].invoke
    else
      admin_user.email = 'admin@vishub.org'
      admin_user.password = "demonstration"
      admin_user.save(:validate => false)
      printTitle("Admin user created with email: '"+admin_user.email+"' and password '"+admin_user.password+"'.")
    end

    #Removing private messages
    Receipt.delete_all
    Notification.delete_all
    Conversation.delete_all
    Message.delete_all

    #Removing QuizSession results
    QuizSession.delete_all
    QuizAnswer.delete_all

    #Removing Tracking System data
    if args[:interactions]!="true"
      TrackingSystemEntry.delete_all
    else
      #Anonymize Tracking System data
      TrackingSystemEntry.record_timestamps=false

      trackers = ['ViSH Viewer']
      TrackingSystemEntry.where("app_id not IN (?)",trackers).delete_all

      #ViSH Viewer data
      vvEntries = TrackingSystemEntry.where("app_id='ViSH Viewer'")
      vvEntries.where("related_entity_id is NULL").delete_all

      vvEntries.find_each batch_size: 1000 do |e|
        d = JSON(e.data) rescue {}
        unless LoInteraction.isValidInteraction?(d)
          e.delete
          next
        end
        d.delete("user")
        unless d["lo"].blank? or d["lo"]["content"].blank?
          d["lo"]["content"].delete("author")
          d["lo"]["content"].delete("vishMetadata")
        end
        unless d["rs"].blank? or d["rs"]["tdata"].blank?
          d["rs"]["tdata"].keys.each do |key|
            d["rs"]["tdata"][key].delete("author")
          end
        end

        e.data = d.to_json
        e.save
      end

      TrackingSystemEntry.record_timestamps=true
    end
    

    #Anonymizing comments
    Comment.all.each do |c|
      c.activity_object.update_column :description, Faker::Lorem.sentence(20, true)
    end

    #Updating excursion authors
    Rake::Task["fix:authors"].invoke

    User.record_timestamps=true
    Actor.record_timestamps=true
    Profile.record_timestamps=true
    Comment.record_timestamps=true
    ActivityObject.record_timestamps=true

    printTitle("Task Finished")
  end

  #Usage
  #Development:   bundle exec rake db:install
  #In production: bundle exec rake db:install RAILS_ENV=production
  desc "Install database for new ViSH instance"
  task :install => :environment do
    printTitle("Installation: populating database")

    Rake::Task["db:reset"].invoke
    Rake::Task["db:seed"].invoke
    Rake::Task["db:populate:create:roles"].invoke
    Rake::Task["db:populate:create:licenses"].invoke
    Rake::Task["db:populate:create:current_site"].invoke
    Rake::Task["db:populate:create:demo_user"].invoke
    Rake::Task["db:populate:create:admin"].invoke

    #Create excursions
    eURL = Vish::Application.config.full_domain + "/examples/"
    author = Actor.find_by_slug("demo")
    e = Excursion.create! :json => '{"VEVersion":"0.8.9","type":"presentation","title":"SCORM and Games","description":"Integration of SCORM Packages into Web Games. Presentation of the SGAME framework.","avatar":"'+eURL+'SGAME-0.jpg","author":{"name":"Aldo","vishMetadata":{"id":20}},"tags":["SCORM","Games","e-Learning","Education"],"theme":"theme1","animation":"animation1","language":"en","context":"higher education","age_range":"18 - 30","difficulty":"easy","TLT":"PT15M","subject":["Education","Software Engineering"],"educational_objectives":"Integration of SCORM Packages into Web Games. Presentation of the SGAME framework.","vishMetadata":{"draft":"false","id":"1057"},"slides":[{"id":"article3","type":"standard","template":"t10","elements":[{"id":"article3_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-0.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article4","type":"standard","template":"t10","elements":[{"id":"article4_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-1.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article5","type":"standard","template":"t10","elements":[{"id":"article5_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-2.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article6","type":"standard","template":"t10","elements":[{"id":"article6_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-3.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article7","type":"standard","template":"t10","elements":[{"id":"article7_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-4.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article8","type":"standard","template":"t10","elements":[{"id":"article8_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-5.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article9","type":"standard","template":"t10","elements":[{"id":"article9_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-6.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article10","type":"standard","template":"t10","elements":[{"id":"article10_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-7.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article11","type":"standard","template":"t10","elements":[{"id":"article11_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-8.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article12","type":"standard","template":"t10","elements":[{"id":"article12_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-9.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article13","type":"standard","template":"t10","elements":[{"id":"article13_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-10.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article14","type":"standard","template":"t10","elements":[{"id":"article14_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-11.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article15","type":"standard","template":"t10","elements":[{"id":"article15_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-12.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article16","type":"standard","template":"t10","elements":[{"id":"article16_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-13.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article17","type":"standard","template":"t10","elements":[{"id":"article17_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-14.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article18","type":"standard","template":"t10","elements":[{"id":"article18_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-15.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article19","type":"standard","template":"t10","elements":[{"id":"article19_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-16.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article20","type":"standard","template":"t10","elements":[{"id":"article20_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-17.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]},{"id":"article21","type":"standard","template":"t10","elements":[{"id":"article21_zone1","type":"image","areaid":"center","body":"'+eURL+'SGAME-18.jpg","style":"position: relative; width:100%; height:100%; top:0%; left:0%;","options":{"vishubPdfexId":"396"}}]}]}',
                          :author_id  => author.id,
                          :owner_id   => author.id,
                          :user_author_id => author.id
    e.save!

    printTitle("Starting search engine and reindexing data (Thinking Sphinx)")
    Rake::Task["ts:rebuild"].invoke
    
    printTitle("Populate finished")
  end

end

