Code.require_file "../../mix_helpers.exs", __DIR__

defmodule Mix.Tasks.CoherenceOauth2.InstallTest do
  use ExUnit.Case
  import MixHelper

  defmodule MigrationsRepo do
    def __adapter__ do
      true
    end

    def config do
      [priv: "tmp", otp_app: :coherence_oauth2]
    end
  end

  setup do
    :ok
  end

  @web_path "lib/coherence_oauth2_web"
  @all_template_dirs ~w(auth registration)

  test "generates files" do
    in_tmp "generates_files", fn ->
      ~w( --no-migrations --no-update-coherence)
      |> Mix.Tasks.CoherenceOauth2.Install.run

      ~w(registration)
      |> assert_dirs(@all_template_dirs, web_path("templates/coherence_oauth2/"))
    end
  end

  test "does not generate files for no boilerplate" do
    in_tmp "does_not_generate_files_for_no_boilerplate", fn ->
      ~w(--no-boilerplate --no-migrations --no-update-coherence)
      |> Mix.Tasks.CoherenceOauth2.Install.run

      ~w()
      |> assert_dirs(@all_template_dirs, web_path("templates/coherence_oauth2/"))
    end
  end

  test "updates coherence" do
    in_tmp "updates_coherence", fn ->
      File.mkdir_p!("lib/coherence_oauth2_web")
      Mix.Task.reenable "coh.install"
      Mix.Task.run "coh.install", ~w(--full --confirmable --invitable --no-config --repo=CoherenceOauth2.Test.Repo --no-migrations)

      ~w(--no-boilerplate)
      |> Mix.Tasks.CoherenceOauth2.Install.run

      file_path = "lib/coherence_oauth2/coherence/user.ex"
      assert_file file_path, fn file ->
        assert file =~ "use Coherence.Schema"
        assert file =~ "use CoherenceOauth2.Schema"
        assert file =~ "coherence_schema()"
        assert file =~ "coherence_oauth2_schema()"
        refute file =~ "|> validate_coherence(params)"
        assert file =~ "|> validate_coherence_oauth2(params)"
      end

      file_path = "lib/coherence_oauth2_web/views/coherence/coherence_view_helpers.ex"
      assert_file file_path, fn file ->
        assert file =~ "def oauth_links"
        assert file =~ "def oauth_link"
      end

      file_path = "lib/coherence_oauth2_web/templates/coherence/registration/new.html.eex"
      assert_file file_path, fn file ->
        assert file =~ "<%= oauth_links(@conn) %>"
      end

      file_path = "lib/coherence_oauth2_web/templates/coherence/session/new.html.eex"
      assert_file file_path, fn file ->
        assert file =~ "<%= oauth_links(@conn) %>"
      end
    end
  end

  test "adds migrations" do
    in_tmp "migrations", fn ->
      ~w(--no-templates --no-update-coherence --migration-path=./)
      |> Mix.Tasks.CoherenceOauth2.Install.run

      assert [_] = Path.wildcard("*_create_user_identities_tables.exs")
    end
  end

  def assert_dirs(dirs, full_dirs, path) do
    Enum.each dirs, fn dir ->
      assert File.dir? Path.join(path, dir)
    end
    Enum.each full_dirs -- dirs, fn dir ->
      refute File.dir? Path.join(path, dir)
    end
  end

  def assert_file_list(files, full_files, path) do
    Enum.each files, fn file ->
      assert_file Path.join(path, file)
    end
    Enum.each full_files -- files, fn file ->
      refute_file Path.join(path, file)
    end
  end

  def web_path(path) do
    Path.join @web_path, path
  end
end
