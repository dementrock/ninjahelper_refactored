source 'https://rubygems.org'

def gem_available?(name)
   Gem::Specification.find_by_name(name)
rescue Gem::LoadError
   false
rescue
   Gem.available?(name)
end

gem 'rails', '3.2.3'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'

gem 'json'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platform => :ruby

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

gem 'nokogiri'

gem 'ampex'

gem 'time_of_day'

# user authentication
gem 'devise'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'ruby-debug'
#
#
group :development do
  # Refresh browser on save
  gem 'awesome_print'
  gem 'rack-livereload'
  gem 'guard-livereload'

  # Autorun tests on save
  gem 'guard-rspec'

  # Restart server when config changes
  if gem_available?('guard-rails')
    gem 'guard-rails'
  end

  # Faster than webrick and doesn't have annoying spam
  gem 'thin'

  # For debugging
  gem 'pry'

  # Annotate models with schema info
  gem 'annotate', :git => 'git://github.com/ctran/annotate_models.git'

  # Color coding in irb and stuff
  gem 'brice'

  gem "rails-erd"
end
