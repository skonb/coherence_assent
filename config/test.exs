use Mix.Config

config :coherence,
  user_schema: CoherenceOauth2.Test.User,
  repo: CoherenceOauth2.Test.Repo,
  module: CoherenceOauth2.Test.CoherenceOauth2,
  web_module: CoherenceOauth2.Test.CoherenceOauth2.Web,
  router: CoherenceOauth2.Test.Router,
  messages_backend: CoherenceOauth2.Test.Coherence.Messages,
  logged_out_url: "/",
  email_from_name: "Your Name",
  email_from_email: "yourname@example.com",
  opts: [:authenticatable, :recoverable, :lockable, :trackable, :unlockable_with_token, :confirmable, :registerable]

config :coherence_oauth2, ecto_repos: [CoherenceOauth2.Test.Repo]
config :coherence_oauth2, CoherenceOauth2.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "coherence_oauth2_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test"
config :coherence_oauth2, CoherenceOauth2.Test.Endpoint,
  secret_key_base: "1lJGFCaor+gPGc21GCvn+NE0WDOA5ujAMeZoy7oC5un7NPUXDir8LAE+Iba5bpGH",
  render_errors: [view: CoherenceOauth2.Test.ErrorView, accepts: ~w(html json)]
