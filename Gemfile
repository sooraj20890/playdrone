source 'https://rubygems.org/'

gem 'rails'
gem 'redis'
# gem 'hiredis', :git => 'git://github.com/nviennot/hiredis-rb.git'
gem 'sidekiq'
gem 'faraday', '~> 0.8.7'
gem 'faraday_middleware'
gem 'net-http-persistent'
gem 'protobuf', git: 'git://github.com/nviennot/protobuf.git', :branch => 'dev'
gem 'stretcher', git: 'git://github.com/PoseBiz/stretcher.git'
gem 'hashie'
gem 'rugged'
gem 'middleware'
gem 'multi_json'
gem 'oj'
gem 'statsd-instrument'
# gem 'airbrake'
gem 'whenever', :require => false
gem 'nokogiri', :require => false
gem "ruby-progressbar", :require => false
gem 'text', git: 'git://github.com/threedaymonk/text.git'
gem 'rubyzip', :require => false
gem 's3', :require => false

# Front end only
gem 'unicorn', :require => false
gem 'slim'
gem 'will_paginate'
gem 'haml-rails'
gem 'jquery-rails'
gem 'therubyracer'
gem 'less-rails'
gem 'twitter-bootstrap-rails', git: 'https://github.com/seyhunak/twitter-bootstrap-rails.git'
gem 'sinatra', :require => false
gem 'coderay'
# Front end only

group :development do
  gem 'foreman',           :require => false
  gem 'capistrano',        :require => false
  gem 'capistrano_colors', :require => false
  gem 'rvm-capistrano',    :require => false
  gem 'guard-livereload',  :require => false
  #gem 'gsl', :require => false

  # token validation
  gem 'oauth',   :require => false
  gem 'oauth2',  :require => false
  gem 'signet',  :require => false
  gem 'aws-sdk', :require => false
end

group :assets do
  gem 'sass-rails',   '~> 3.2.3', :require => false
  gem 'coffee-rails', '~> 3.2.1', :require => false
  gem 'uglifier',     '>= 1.0.3', :require => false
end
