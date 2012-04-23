source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'

# Bundle edge Rails instead:
# gem 'rails',     :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'pg'
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.4'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '>= 1.2.3'
end

gem 'jquery-rails'

social_stream_gems = lambda {
  gem 'social_stream-base'
  gem 'social_stream-documents'
  gem 'social_stream-linkser'
}

# Developing Social Stream
if ENV['VISH_DEV']
  path '../social_stream-vish', &social_stream_gems
else
  git 'git://github.com/ging/social_stream.git', :branch => 'vish', &social_stream_gems
end

git 'git://github.com/ging/vish_editor.git', :branch => 'stable' do
  gem 'vish_editor'
end

# Force the first version of avatars_for_rails that does not collide with bootstrap
gem 'avatars_for_rails', '~> 0.2.6'

#gem 'vish_editor', :path => '../vish_editor/rails'

# We do not know the reasons for this gem:
#gem 'therubyracer'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# Use god for its own purpose
gem 'god'

# Use exception notification
gem 'exception_notification'

# Be able to pass tests
gem 'rspec-rails'

group :test do
  # Pretty printed test output
  gem 'factory_girl', '~> 2.6'
  gem 'capybara'
end

group :development do
  gem 'forgery'

  # Debug with Ruby 1.9.2
  if ENV['VISH_DEV']
    gem "debugger", "~> 1.1.1"
    #gem 'ruby-debug19', :require => 'ruby-debug'
  end
end

