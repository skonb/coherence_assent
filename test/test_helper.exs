ExUnit.start()
Application.ensure_all_started(:bypass)

web_path = "tmp/coherence/web"
if File.dir? "tmp/coherence" do
  File.rm_rf! "tmp/coherence"
end
File.mkdir_p! web_path

migrations_path = "priv/test/migrations"
if File.dir? migrations_path do
  File.rm_rf! migrations_path
end
File.mkdir_p! migrations_path

Mix.Task.run "coh.install", ~w(--full --confirmable --invitable --no-config --no-models --no-views --no-templates --no-web --no-messages --web-path=#{web_path} --no-controllers --repo=CoherenceOauth2.Test.Repo)
Mix.Task.run "coherence_oauth2.install", ~w(--no-templates --no-update-coherence)
Mix.Task.run "ecto.drop"
Mix.Task.run "ecto.create"
Mix.Task.run "ecto.migrate"

{:ok, _pid} = CoherenceOauth2.Test.Endpoint.start_link
{:ok, _pid} = CoherenceOauth2.Test.Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(CoherenceOauth2.Test.Repo, :manual)
