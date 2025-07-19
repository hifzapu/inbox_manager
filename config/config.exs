# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :inbox_manager,
  ecto_repos: [InboxManager.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :inbox_manager, InboxManagerWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: InboxManagerWeb.ErrorHTML, json: InboxManagerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: InboxManager.PubSub,
  live_view: [signing_salt: "RKgtE2+K"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :inbox_manager, InboxManager.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
config :esbuild,
  version: "0.17.11",
  inbox_manager: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.3",
  inbox_manager: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"

config :ueberauth, Ueberauth,
  providers: [
    google:
      {Ueberauth.Strategy.Google,
       [
         default_scope: "email profile https://www.googleapis.com/auth/gmail.readonly",
         access_type: "offline",
         include_granted_scopes: true
       ]}
  ]

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: "1099192373321-tggn4htol6q85p45l5jlv92e8b6fmk9q.apps.googleusercontent.com",
  client_secret: "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"
