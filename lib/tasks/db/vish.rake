#
# You've got to love rake here:
# to patch social_stream's populate.rake, you can name this file anything but populate.rake
#

namespace :db do

  namespace :populate do
    # Clear existing tasks
    task(:create_ties).prerequisites.clear
    task(:create_ties).clear
    %w( db:seed create:groups ).each do |t|
      task(:create).prerequisites.delete(t)
    end

    # User 12 logos
    ENV['LOGOS_TOTAL'] = 12.to_s

    desc "Create populate data for ViSH"
    task :create => [ 'create:occupations', 'create:excursions', 'create:current_site']
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

        # Some sample science images in the public domain
        @sample_images = %w{
          http://s0.geograph.org.uk/geophotos/01/74/36/1743675_513c1a7a.jpg
          http://i.images.cdn.fotopedia.com/flickr-119671566-hd/Endangered_Species/Least_Concern/Gray_Wolf/Gray_Wolf_Canis_lupus.jpg
          http://lucaskrech.com/blog/wp-content/uploads/2010/07/Screen-shot-2010-07-15-at-9.05.45-PM.png
          http://images.cdn.fotopedia.com/flickr-3417427945-hd.jpg
          http://2.bp.blogspot.com/_QEWhOURarSU/SMesG6Wt0iI/AAAAAAAACZY/3LBoehU1SpQ/s320/lhc.jpg
          http://images.cdn.fotopedia.com/flickr-3507973704-hd.jpg
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
                                :relation_ids => [Relation::Public.instance.id],
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
                                :relation_ids => [Relation::Public.instance.id],
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

        Site.current.config["tmpCounter"] = 1
        Site.current.save!

        current_site_end = Time.now
        puts '   -> ' +  (current_site_end - current_site_start).round(4).to_s + 's'
      end
    end
  end

  #Usage
  #Development:   bundle exec rake db:anonymize
  #In production: bundle exec rake db:anonymize RAILS_ENV=production
  task :anonymize => :environment do
    printTitle("Anonymizing database")

    #TODO...

    printTitle("Task Finished")
  end

end

