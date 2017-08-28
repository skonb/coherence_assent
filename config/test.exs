use Mix.Config

config :coherence_oauth2, ecto_repos: [CoherenceOauth2.Test.Repo]
config :coherence_oauth2, CoherenceOauth2.Test.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "coherence_oauth2_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  priv: "priv/test"
