source 'https://rubygems.org'

# For more information on Bundler groups: http://bundler.io/groups.html

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.1.1'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 1.2'

group :doc do
  # bundle exec rake doc:rails generates the API under doc/api.
  gem 'sdoc', require: false
end

group :development do
  # Use sqlite3 as the database for Active Record
  gem 'sqlite3'

  # Capistrano deployment
  gem 'capistrano', '~> 3.2.0'
  gem 'capistrano-rails', '~> 1.1.0'

  # Using thin for development server
  gem 'thin'
end

# Use debugger
# gem 'debugger', group: [:development, :test]

# Postgresql db
gem 'pg', group: [:staging, :production]

# Additional gems
gem 'sorcery', '0.8.5' # authentication
gem 'paperclip' # attachments, images and thumbnails
gem 'acts-as-taggable-on' # tags
gem 'redcarpet' # for translating markdown into HTML
gem 'reverse_markdown' # for translating HTML into markdown
gem 'versioncake' # API versioning
#gem 'actionpack-xml_parser' # XML parameters parsing for Atom, etc.
#gem 'acts_as_list' # for ordered lists in objects
gem 'rmagick' # image manipulation from within ruby
gem 'cocaine' # command line wrapper, useful for determining file mime types
gem 'parchment' # Word processing file parser, DOCX, ODT, etc.
gem 'rack-cors', :require => 'rack/cors' # CORS for API sharing
gem 'redis'
gem 'will_paginate', '~> 3.0'
