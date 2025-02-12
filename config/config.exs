# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :thesis, ThesisWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Uqz3utAOWmiwz3MsYCCB4QKjKg7bReiKg1wj4z5ryAEHCQMHioxz6JtQTlULGPtm",
  render_errors: [
    view: ThesisWeb.ErrorView,
    accepts: ~w(html),
    layout: {ThesisWeb.ErrorView, "error.html"}
  ],
  pubsub: [name: Thesis.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
    signing_salt: "YOUR_SECRET"
  ]

config :thesis, :children, [ThesisWeb.Endpoint, Thesis.Repo]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :plug_lti,
  lti_key: "test",
  lti_secret: "secret"

config :phoenix,
  template_engines: [leex: Phoenix.LiveView.Engine]

config :thesis, ecto_repos: [Thesis.Repo]

# config :thesis, Thesis.Repo,
#   database: "thesis_repo",
#   username: "postgres",
#   password: "postgres",
#   hostname: "localhost"

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
