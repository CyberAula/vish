# Call this script with the following syntax:
# bundle exec cap deploy DEPLOY=myEnvironment
# Where myEnvironment is the name of the xml file (config/deploy/myEnvironment.xml) which defines the deployment.

require 'yaml'
require "bundler/capistrano"

begin
  config = YAML.load_file(File.expand_path('../deploy/' + ENV['DEPLOY'] + '.yml', __FILE__))
  puts config["message"]
  repository = config["repository"]
  server_url = config["server_url"]
  username = config["username"]
  keys = config["keys"]
  branch = config["branch"] || "master"
  with_workers = config["with_workers"]
rescue Exception => e
  #puts e.message
  puts "Sorry, the file config/deploy/" + ENV['DEPLOY'] + '.yml does not exist.'
  exit
end

set :keep_releases, 2

set :default_environment, {
  'PATH' => '/home/'+username+'/.rvm/gems/ruby-2.2.0/bin:/home/'+username+'/.rvm/gems/ruby-2.2.0@global/bin:/home/'+username+'/.rvm/rubies/ruby-2.2.0/bin:/home/'+username+'/.rvm/bin:/home/'+username+'/.rbenv/plugins/ruby-build/bin:/home/'+username+'/.rbenv/shims:/home/'+username+'/.rbenv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games',
  'RUBY_VERSION' => 'ruby-2.2.0p0',
  'GEM_HOME'     => '/home/'+username+'/.rvm/gems/ruby-2.2.0',
  'GEM_PATH'     => '/home/'+username+'/.rvm/gems/ruby-2.2.0:/home/'+username+'/.rvm/gems/ruby-2.2.0@global',
  'BUNDLE_PATH'  => '/home/'+username+'/.rvm/gems/ruby-2.2.0:/home/'+username+'/.rvm/gems/ruby-2.2.0@global'
}

# Where we get the app from and all...
set :scm, :git
set :repository, repository

puts "Using branch: '" + branch + "'"
set :branch, fetch(:branch, branch)

# Some options
default_run_options[:pty] = true
ssh_options[:forward_agent] = true
if keys
  ssh_options[:keys] = keys
end

# Servers to deploy to
set :application, "vish"
set :user, username

role :web, server_url # Your HTTP server, Apache/etc
role :app, server_url # This may be the same as your `Web` server
role :db,  server_url, :primary => true # This is where Rails migrations will run

after 'deploy:update_code', 'deploy:fix_file_permissions'
#after 'deploy:update_code', 'deploy:link_files'
before 'deploy:assets:precompile', 'deploy:link_files'
before 'deploy:restart', 'deploy:start_sphinx'
after  'deploy:start_sphinx', 'deploy:fix_sphinx_file_permissions'
if with_workers
  after 'deploy:restart', 'deploy:stop_workers'
end
after 'deploy:update_code', 'deploy:rm_dot_git', 'rvm:trust_rvmrc'
after "deploy:restart", "deploy:cleanup"


namespace(:deploy) do
  # Tasks for passenger mod_rails
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end

  # Other tasks
  task :fix_file_permissions do
    # LOG
    run "#{try_sudo} touch #{release_path}/log/production.log"
    run "#{try_sudo} /bin/chmod 666 #{release_path}/log/production.log"

    # TMP
    run "/bin/chmod -R g+w #{release_path}/tmp"
    sudo "/bin/chgrp -R www-data #{release_path}/tmp"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/tmp/json"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/tmp/scorm"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/tmp/qti"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/tmp/moodlequizxml"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/tmp/simple_captcha"

    # config.ru
    sudo "/bin/chown www-data #{release_path}/config.ru"

    # SCORM
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/scorm/12"
    run "#{try_sudo} /bin/chmod -R 777 #{release_path}/public/scorm/2004"
  end

  task :link_files do
    run "ln -s #{shared_path}/documents #{release_path}/"
    run "ln -s #{shared_path}/webappscode #{release_path}/public/webappscode"
    run "ln -s #{shared_path}/imscppackages #{release_path}/public/imscp/packages"
    run "ln -s #{shared_path}/scormpackages #{release_path}/public/scorm/packages"
    run "ln -s #{shared_path}/database.yml #{release_path}/config"
    run "ln -s #{shared_path}/application_config.yml #{release_path}/config"
    run "ln -s #{shared_path}/exception_notification.rb #{release_path}/config/initializers"
    run "ln -s #{shared_path}/social_stream-ostatus.rb #{release_path}/config/initializers"
    run "ln -s #{shared_path}/sitemap #{release_path}/public/sitemap"
  end

  task :start_sphinx do
    run "cd #{current_path} && kill -9 `cat log/searchd.production.pid` || true"
    run "cd #{release_path} && bundle exec \"rake ts:rebuild RAILS_ENV=production\""
  end

  task :rm_dot_git do
    run "cd #{release_path} && rm -rf .git"
  end

  task :fix_sphinx_file_permissions do
    run "/bin/chmod g+rw #{release_path}/log/searchd*"
    sudo "/bin/chgrp www-data #{release_path}/log/searchd*"
  end

  task :stop_workers do
    sudo_command = "rvmsudo"    
    run "cd #{current_path} && #{sudo_command} bundle exec \"rake workers:killall RAILS_ENV=production\""
  end

end

namespace :rvm do
  task :trust_rvmrc do
    run "rvm rvmrc trust #{release_path} < /dev/null"
  end
end