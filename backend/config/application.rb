require_relative "boot"

require "rails/all"

# ★ 追加: rack-cors を読み込む
require "rack/cors"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # ★ 追加: CORS 設定（Next.js: http://localhost:8000 から Rails: http://localhost:3000 を叩けるようにする）
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "http://localhost:8000"

        resource "*",
          headers: :any,
          methods: %i[get post put patch delete options head],
          expose: ["Authorization"],
          max_age: 600
      end
    end

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true
  end
end
