import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :inbox_manager, InboxManager.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "inbox_manager_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :inbox_manager, InboxManagerWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ospDUEZRQzYI6Gl/R9JgV2QzFv6FG7OvUpFK9l3lFNCyiIVtt6PqtMapO8oYHPk9",
  server: false

# In test we don't send emails.
config :inbox_manager, InboxManager.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Configure Oban for testing - disable job processing
config :inbox_manager, Oban, testing: :manual

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true
