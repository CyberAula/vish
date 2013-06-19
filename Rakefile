#!/usr/bin/env rake

require 'rspec/core'
require 'rspec/core/rake_task'
require 'resque/tasks'

require File.expand_path('../config/application', __FILE__)

Resque.after_fork = Proc.new { ActiveRecord::Base.establish_connection } if Resque.present?

# Include social_stream-base spec
def bsp(str)
  base_spec_path = File.join(Gem::Specification.find_by_name('social_stream-base').full_gem_path, 'spec/')
  File.join(base_spec_path, str)
end
RSpec::Core::RakeTask.new(:spec) do |s|
  s.pattern = ['./spec/**/*_spec.rb',
                bsp('./controllers/users_controller_spec.rb'),
                bsp('./controllers/notifications_controller_spec.rb'),
                bsp('./controllers/likes_controller_spec.rb'),
                # bsp('./controllers/profiles_controller_spec.rb'),
                bsp('./controllers/comments_controller_spec.rb'),
                bsp('./controllers/frontpage_controller_spec.rb'),
                # bsp('./controllers/posts_controller_spec.rb'),
                bsp('./controllers/representations_spec.rb'),
                # bsp('./controllers/groups_controller_spec.rb'),
                bsp('./controllers/settings_controller_spec.rb'),
                bsp('./models/profile_spec.rb'),
                bsp('./models/user_spec.rb'),
                bsp('./models/tie_spec.rb'),
                # bsp('./models/activity_spec.rb'),
                bsp('./models/actor_spec.rb'),
                # bsp('./models/group_spec.rb'),
                bsp('./models/like_spec.rb'),
                bsp('./models/post_spec.rb')
	      ]
end

task :default => [ :spec, 'assets:precompile' ]

Vish::Application.load_tasks
