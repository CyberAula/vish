source 'http://rubygems.org'

gem 'rails', '~> 3.2.0'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'
gem 'pg'
gem 'mysql2'

# Gems used only for assets and not required
# in production environments by default.
  gem 'sass-rails', '~> 3.2.4'
  gem 'bootstrap-sass', '~> 2.1.0.0'
  gem 'coffee-rails', '~> 3.2.2'
  gem 'uglifier', '>= 1.2.3'

gem 'jquery-rails', '2.0.2'
gem 'json', '1.7.4'
gem 'sinatra', '1.3.2'

social_stream_gems = lambda {
  gem 'social_stream-base'
  gem 'social_stream-documents'
  gem 'social_stream-linkser'
  gem 'social_stream-ostatus'
}

# Developing Social Stream
#if ENV['VISH_DEV']
if File.exists?("../social_stream-bootstrap")
#  path '../social_stream-vish', &social_stream_gems
  path '../social_stream-bootstrap', &social_stream_gems
else
  git 'git://github.com/ging/social_stream.git', :branch => 'bootstrap', &social_stream_gems
end

# Force the first version of avatars_for_rails that does not collide with bootstrap
gem 'avatars_for_rails', '~> 0.2.6'

# Composite keys for vish-recsys
gem 'composite_primary_keys'

# We do not know the reasons for this gem:
#gem 'therubyracer'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
group :development do
  gem 'capistrano'
  gem 'rvm-capistrano'
end

# Use god for its own purpose
gem 'god'

# Use exception notification
gem 'exception_notification'

# Be able to pass tests
gem 'rspec-rails', '=2.9.0'
gem 'net-ssh', '=2.4.0'

# Shortener
gem 'shortener'

group :test do
  # Pretty printed test output
  gem 'factory_girl', '~> 2.6'
  gem 'capybara'
end

group :development do
  gem 'forgery'

  # Debug with Ruby 1.9.2
  # use with:
  # $ export VISH_DEBUG=true

  if ENV['VISH_DEV'] || ENV['VISH_DEBUG']
    gem "debugger", "~> 1.1.1"
  end

  if ENV['VISH_DEV_ALTERNATIVE']
    gem 'ruby-debug19', :require => 'ruby-debug'
  end

end
