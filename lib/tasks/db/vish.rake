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
    task :create => [ :read_environment, :create_users, :create_ties, :create_avatars ]

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

  end
end

