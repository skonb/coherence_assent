defmodule TestHelpers do
  defp clear_path(path) do
    if File.dir? path do
      File.rm_rf! path
    end
    File.mkdir_p! path
  end

  defp save_app_file(path) do
    # Add app layout file
    layout_path = path <> "/templates/layout"
    File.mkdir_p! layout_path
    {:ok, file} = File.open layout_path <> "/app.html.eex", [:write]
    IO.binwrite file, "<%= render @view_module, @view_template, assigns %>"
    File.close file
  end

  def setup do
    web_path = "tmp/coherence/web"
    clear_path(web_path)
    save_app_file(web_path)
    clear_path("priv/test/migrations")
    install_coherence(web_path)
    recompile()
    setup_db()
  end

  defp install_coherence(web_path) do
    Mix.Task.run "coh.install", ~w(--full --confirmable --invitable --no-config --no-models --no-views --no-web --no-messages --web-path=#{web_path} --no-controllers --repo=CoherenceAssent.Test.Repo --silent)
    Mix.Task.run "coherence_assent.install", ~w(--no-update-coherence --web-path=#{web_path} --silent)
  end

  defp recompile do
    Mix.Task.reenable "compile.elixir"
    Mix.Task.run "compile.elixir"
  end

  defp setup_db do
    Mix.Task.run "ecto.drop"
    Mix.Task.run "ecto.create"
    Mix.Task.run "ecto.migrate"
  end
end

Logger.configure(level: :error)
TestHelpers.setup()
Logger.configure(level: :info)

ExUnit.start()
Application.ensure_all_started(:bypass)

{:ok, _pid} = CoherenceAssent.Test.Web.Endpoint.start_link
{:ok, _pid} = CoherenceAssent.Test.Repo.start_link

Ecto.Adapters.SQL.Sandbox.mode(CoherenceAssent.Test.Repo, :manual)
