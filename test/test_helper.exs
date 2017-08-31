ExUnit.start()
Application.ensure_all_started(:bypass)

# Mix.Task.run "coh.install", ~w(--silent --no-migrations --no-config --confirm-once)
Mix.Task.run "ecto.drop"
Mix.Task.run "ecto.create"
Mix.Task.run "ecto.migrate"

{:ok, _pid} = CoherenceOauth2.Test.Endpoint.start_link
{:ok, _pid} = CoherenceOauth2.Test.Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(CoherenceOauth2.Test.Repo, :manual)
