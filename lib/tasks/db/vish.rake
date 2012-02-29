#
# You've got to love rake here:
# to patch social_stream's populate.rake, you can name this file anything but populate.rake
#

namespace :db do
  namespace :populate do
    # Clear existing tasks
    task(:create).prerequisites.clear
    task(:create).clear
    task(:create_ties).prerequisites.clear
    task(:create_ties).clear

    desc "Create populate data for ViSH"
    task :create => [ :read_environment, :create_users, :create_ties, :create_posts, :create_messages, :create_excursions, :create_avatars ]

    desc "Create Ties as follows and rejects only"
    task :create_ties do
      puts 'Follows population'
      ties_start = Time.now

      @available_actors.each do |a|
        actors = @available_actors.dup - Array(a)
	relations = [ Relation::Follow.instance, Relation::Reject.instance ]
	break if actors.size==0
	Forgery::Basic.number(:at_most => actors.size).times do
	  actor = actors.delete_at((rand * actors.size).to_i)
	  contact = a.contact_to!(actor)
	  contact.relation_ids = Array(Forgery::Extensions::Array.new(relations).random.id) unless a==actor
	end
      end

      ties_end = Time.now
      puts '   -> ' +  (ties_end - ties_start).round(4).to_s + 's'
    end

    desc "Populate excursions to the database"
    task :create_excursions do
      puts 'Excursion population'
      excursions_start = Time.now

      def generate_slide
	{ # Slide N
	  :id => "vish#{}",
          :template => 't1',
          :elements => [
	    { # Element 1
	      :type => 'text',
	      :areaid => 'header',
	      :body => Forgery::LoremIpsum.words(1+rand(4),:random => true)
            },
	    { # Element 2
	      :type => 'text',
	      :areaid => 'right',
	      :body => Forgery::LoremIpsum.paragraph(:random => true)
            },
	    { # Element 3
	      :type => 'text',
	      :areaid => 'left',
	      :body => Forgery::LoremIpsum.paragraph(:random => true)
            }
	  ]
	}
      end

      10.times do
        updated = Time.at(rand(Time.now.to_i))
	author = @available_actors[rand(@available_actors.size)]
	owner  = author
	user_author =  ( author.subject_type == "User" ? author : author.user_author )

        Excursion.create! :title => 'Title: ' + Forgery::LoremIpsum.words(1+rand(4),:random => true),
	                  :description => 'Description: ' + Forgery::LoremIpsum.paragraph(:random => true),
	                  :json => Array.new(1+rand(9)).map{ generate_slide }.to_json,
	                  :created_at => Time.at(rand(updated.to_i)),
			  :updated_at => updated,
			  :author_id  => author.id,
			  :owner_id   => owner.id,
			  :user_author_id => user_author.id
      end

      excursions_end = Time.now
      puts '   -> ' +  (excursions_end - excursions_start).round(4).to_s + 's'
    end

  end
end

