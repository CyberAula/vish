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

# Developing Social Stream
git 'git://github.com/ging/social_stream.git', :branch => 'vish' do
  gem 'social_stream-base'
  gem 'social_stream-documents'
  gem 'social_stream-linkser'
end

#gem 'social_stream-base'
#gem 'social_stream-documents'
#gem 'social_stream-linkser'

gem 'vish_editor', :path => '../vish_editor/rails'

gem 'therubyracer'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
gem 'capistrano'

# Use exception notification
gem 'exception_notification'

# Be able to pass tests
gem 'rspec-rails'

group :test do
  # Pretty printed test output
  gem 'factory_girl'
  gem 'capybara'
end

group :development do
  gem 'forgery'

  if RUBY_VERSION > '1.9'
    gem 'ruby-debug19', :require => 'ruby-debug'
  end
end

