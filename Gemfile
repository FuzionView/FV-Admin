source "https://rubygems.org"

ruby "~> 3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"

# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
gem "turbo-rails"
gem 'stimulus-rails'

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
# gem "bcrypt", "~> 3.1.7"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ mswin mswin64 mingw x64_mingw jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "bundler-audit"
  gem "brakeman", "~> 6.0" # Required for Ruby 3.0"
  gem "debug", platforms: %i[ mri mswin mswin64 mingw x64_mingw ]
  gem "rubocop-rails"
end

group :test do
   gem "mocha"
   gem 'simplecov'
end

gem "dotenv", "~> 3.1"

gem "simple_form", "~> 5.3"

gem "omniauth_openid_connect", "~> 0.7.1"
gem "omniauth-rails_csrf_protection"

gem "pundit", "~> 2.3"

gem "httparty", "~> 0.22.0"

# Pin
gem "rack", "~> 2.2" # Need to verify if passenger version works with 3.0
gem "securerandom", "= 0.3.2" # Required for Ruby 3.0"
gem "nokogiri", "~> 1.17.0" # Required for Ruby 3.0"
gem "zeitwerk", "~> 2.6.0" # Required for Ruby 3.0
gem "net-imap", "~> 0.4.18" # Required for Ruby 3.0
