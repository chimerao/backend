require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env)

module Imaginate
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Making sure this is set as default. Rails >= 4.1
    config.action_dispatch.cookies_serializer = :json

    # Versioncake API versioning
    # https://github.com/bwillis/versioncake
    config.versioncake.supported_version_numbers = [1]
    config.versioncake.extraction_strategy = :http_accept_parameter

    # Additional parsing for XML parameters (for Atom API)
    # Also see: http://matthewtodd.org/2008/04/25/rails-tip-5-atom-param-parser.html
    # config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :patch, :delete, :options]
      end
    end
  end
end
