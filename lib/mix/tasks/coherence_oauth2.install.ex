defmodule Mix.Tasks.CoherenceOauth2.Install do
  use Mix.Task

  import Macro, only: [camelize: 1]
  import Mix.Generator
  import Mix.Ecto
  import CoherenceOauth2.Mix.Utils

  @shortdoc "Configure the CoherenceOauth2 Package"

  @moduledoc """
  Configure CoherenceOauth2 for your Phoenix/Coherence application.
  This installer will normally do the following unless given an option not to do so:
    * Update User schema installed by Coherence.
    * Update registration and session templates.
    * Generate appropriate migration files.
    * Generate appropriate template files.
  ## Examples
      mix coherence_oauth2.install
  # ## Option list
  #   * Your Coherence user schema and Coherence templates will be modified unless the `--no-update-coherence` option is given.
  #   * A `--config-file config/config.exs` option can be given to change what config file to append to.
  #   * A `--installed-options` option to list the previous install options.
  #   * A `--silent` option to disable printing instructions
  #   * A `--web-path="lib/my_project_web"` option can be given to specify the web path
  #   * A `--migration-path` option to set the migration path
  #   * A `--module` option to override the module
  # ## Disable Options
  #   * `--no-update-coherence` -- Don't update Coherence user file.
  #   * `--no-migrations` -- Don't create any migration files.
  #   * `--no-templates` -- Don't create the `WEB_PATH/templates/coherence_oauth2` files.
  #   * `--no-boilerplate` -- Don't create any of the boilerplate files.
  """

  @all_options       ~w(auth registration)
  @all_options_atoms Enum.map(@all_options, &(String.to_atom(&1)))
  @default_options   ~w(auth registration)

  # the options that default to true, and can be disabled with --no-option
  @default_booleans  ~w(templates boilerplate migrations update_coherence)

  # all boolean_options
  @boolean_options   @default_booleans ++ ~w(default) ++ @all_options

  @switches [
    module: :string, installed_options: :boolean,
    migration_path: :string, web_path: :string, silent: :boolean
  ] ++ Enum.map(@boolean_options, &({String.to_atom(&1), :boolean}))

  @switch_names Enum.map(@switches, &(elem(&1, 0)))

  @doc false
  def run(args) do
    {opts, parsed, unknown} = OptionParser.parse(args, switches: @switches)

    verify_args!(parsed, unknown)

    {bin_opts, opts} = parse_options(opts)

    opts
    |> do_config(bin_opts)
    |> do_run
  end

  defp do_run(%{installed_options: true} = config),
    do: print_installed_options config

  defp do_run(config) do
    config
    |> validate_project_structure
    |> update_coherence_files
    |> gen_coherence_oauth2_templates
    |> gen_migration_files
    |> print_instructions
  end

  defp validate_project_structure(%{web_path: web_path} = config) do
    case File.lstat(web_path) do
      {:ok, %{type: :directory}} ->
        config
      _ ->
        if Mix.shell.yes?("Cannot find web path #{web_path}. Are you sure you want to continue?") do
          config
        else
          Mix.raise "Cannot find web path #{web_path}"
        end
    end
  end
  defp validate_project_structure(config), do: config

  defp validate_option(_, :all), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  ##################
  # Coherence Update

  defp update_coherence_files(%{update_coherence: true} = config) do
    config
    |> update_user_model
    |> update_coherence_view_helpers
    |> update_coherence_templates
  end
  defp update_coherence_files(config), do: config

  defp update_user_model(config) do
    user_path = lib_path("coherence/user.ex")
    case File.lstat(user_path) do
      {:ok, %{type: :regular}} -> update_user_model_file(user_path)
                                  config
      _ -> Mix.raise "Cannot find Coherence user model at #{user_path}"
    end
  end

  defp update_user_model_file(user_path) do
    user_path
    |> File.read!()
    |> add_after_in_user_model("use Coherence.Schema", "use CoherenceOauth2.Schema")
    |> add_after_in_user_model("coherence_schema()", "coherence_oauth2_schema()")
    |> replace_in_user_model("|> validate_coherence(params)", "|> validate_coherence_oauth2(params)")
    |> update_file(user_path)
  end

  defp update_coherence_view_helpers(%{web_path: web_path} = config) do
    helpers_path = Path.join(web_path, "views/coherence/coherence_view_helpers.ex")
    string = """

               @spec oauth_links(conn):: String.t
               def oauth_links(conn) do
                 CoherenceOauth2.clients()
                 |> Keyword.keys()
                 |> Enum.map(fn(provider) -> oauth_link(conn, provider) end)
               end

               @spec oauth_link(conn, String.t | atom) :: String.t
               def oauth_link(conn, provider) do
                 "coherence"
                 |> dgettext("Login with %{provider}", provider: provider)
                 |> link(to: @helpers.coherence_oauth2_auth_path(conn, :index, provider))
               end
             """

    case File.lstat(helpers_path) do
      {:ok, %{type: :regular}} ->
        update_coherence_view_helpers_file(helpers_path, string, ~r/(def oauth\_link)/)
        config
      _ ->
          config
          |> Map.merge(%{
            instructions:
          """
          #{config.instructions}

          Could not find #{helpers_path}.

          Add the following to your view helpers:

          #{string}
          """
          })
    end
  end

  defp update_coherence_view_helpers_file(helpers_path, string, regex_needle) do
    helpers_path
    |> File.read!()
    |> add_to_end_in_module(string, regex_needle)
    |> update_file(helpers_path)
  end

  defp update_coherence_templates(%{web_path: web_path} = config) do
    session_template = Path.join(web_path, "templates/coherence/session/new.html.eex")
    registration_template = Path.join(web_path, "templates/coherence/registration/new.html.eex")
    string = "<%= oauth_links(@conn) %>"

    case {File.lstat(registration_template), File.lstat(session_template)} do
      {{:ok, %{type: :regular}}, {:ok, %{type: :regular}}} ->
        update_coherence_templates(registration_template, string)
        update_coherence_templates(session_template, string)
        config
      _ ->
          config
          |> Map.merge(%{
            instructions:
          """
          #{config.instructions}

          Could not find the following files:
          #{session_template}
          #{registration_template}

          Add "#{string}" to the login and registration template files.
          """
          })
    end
  end

  defp update_coherence_templates(path, string) do
    content = File.read!(path)

    case String.contains?(content, string) do
      true -> content
      _    -> content <> "\n" <> string
    end
    |> update_file(path)
  end

  defp add_after_in_user_model(string, needle, replacement) do
    regex = ~r/^((\s*)#{Regex.escape(needle)})$/m
    regex_replacement = "\\1\n\\2#{replacement}"

    replace(string, regex, regex_replacement, needle, replacement)
  end

  defp replace_in_user_model(string, needle, replacement) do
    regex = ~r/#{Regex.escape(needle)}/

    replace(string, regex, replacement, needle, replacement)
  end

  defp add_to_end_in_module(string, insert, regex_needle) do
    regex = ~r/^defmodule(.*)end$/s
    regex_replacement = "defmodule\\1#{insert}end"
    case Regex.match?(regex_needle, string) do
      true  -> string
      false -> Regex.replace(regex, string, regex_replacement, global: false)
    end
  end

  defp replace(string, regex, regex_replacement, needle, replacement) do
    found_needle = Regex.match?(~r/#{Regex.escape(needle)}/, string)
    found_replacement = Regex.match?(~r/#{Regex.escape(replacement)}/, string)

    case {found_needle, found_replacement} do
      {true, false}  -> Regex.replace(regex, string, regex_replacement, global: false)
      {false, true}  -> string
      {false, false} -> Mix.raise "Can't find #{needle} and add #{replacement} in user schema file"
      {true, true}   -> string
    end
  end

  defp update_file(content, path) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end

  ################
  # Templates

  @template_files [
    registration: {:registration, ~w(add_login_field)}
  ]

  defp gen_coherence_oauth2_templates(%{templates: true, boilerplate: true, binding: binding, web_path: web_path} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files, web_path)
    end
    config
  end
  defp gen_coherence_oauth2_templates(config), do: config

  defp copy_templates(binding, name, file_list, web_path) do
    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate/templates/#{name}", binding, copy_templates_files(name, file_list, web_path)
  end
  defp copy_templates_files(name, file_list, web_path) do
    for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, Path.join(web_path, "templates/coherence/#{name}/#{fname}")}
    end
  end

  ################
  # Instructions

  defp router_instructions(%{base: base}) do
    """
    Configure your router.ex file the following way:

    defmodule #{base}.Router do
      use #{base}Web, :router
      use Coherence.Router
      use CoherenceOauth2.Router         # Add this

      pipeline :browser do
        plug :accepts, ["html"]
        plug :fetch_session
        plug :fetch_flash
        plug :protect_from_forgery
        plug :put_secure_browser_headers
      end

      pipeline :public do
        plug Coherence.Authentication.Session
      end

      pipeline :protected do
        plug Coherence.Authentication.Session, protected: true
      end

      scope "/" do
        pipe_through [:browser, :public]
        coherence_routes()
        coherence_oauth2_routes()        # Add this
      end

      scope "/" do
        pipe_through [:browser, :protected]
        coherence_routes :protected
      end
      ...
    end
    """
  end

  defp migrate_instructions(%{boilerplate: true, migrations: true}) do
    """
    Don't forget to run the new migrations and seeds with:
        $ mix ecto.setup
    """
  end
  defp migrate_instructions(_), do: ""

  defp config_instructions(_) do
    """
    You can configure the OAuth client information the following way:

    config :coherence_oauth2, :providers, [
      github: [
        client_id: "REPLACE_WITH_CLIENT_ID",
        client_secret: "REPLACE_WITH_CLIENT_SECRET",
        handler: CoherenceOauth2.Github
      ]
    ]

    Handlers exists for Facebook, Github, Google and Twitter.
    """
  end

  defp print_instructions(%{silent: true} = config), do: config
  defp print_instructions(%{instructions: instructions} = config) do
    shell_info instructions, config
    shell_info router_instructions(config), config
    shell_info migrate_instructions(config), config
    shell_info config_instructions(config), config

    config
  end

  ################
  # Utilities

  defp do_default_config(config, opts) do
    @default_booleans
    |> list_to_atoms
    |> Enum.reduce(config, fn opt, acc ->
      Map.put acc, opt, Keyword.get(opts, opt, true)
    end)
  end

  defp list_to_atoms(list), do: Enum.map(list, &(String.to_atom(&1)))

  defp paths do
    [".", :coherence_oauth2]
  end

  ############
  # Migrations

  defp gen_migration_files(%{boilerplate: true, migrations: true, repo: repo} = config) do
    ensure_repo(repo, [])

    path =
     case config[:migration_path] do
       path when is_binary(path) -> path
       _                         -> migrations_path(repo)
     end

    create_directory path
    existing_migrations = to_string File.ls!(path)

    for {name, template} <- migrations() do
      create_migration_file(repo, existing_migrations, name, path, template, config)
    end

    config
  end
  defp gen_migration_files(config), do: config

  defp next_migration_number(existing_migrations, pad_time \\ 0) do
    timestamp = NaiveDateTime.utc_now
                |> NaiveDateTime.add(pad_time, :second)
                |> NaiveDateTime.to_erl
                |> padded_timestamp

    if String.match? existing_migrations, ~r/#{timestamp}_.*\.exs/ do
      next_migration_number(existing_migrations, pad_time + 1)
    else
      timestamp
    end
  end

  defp create_migration_file(repo, existing_migrations, name, path, template, config) do
    unless String.match? existing_migrations, ~r/\d{14}_#{name}\.exs/ do
      file = Path.join(path, "#{next_migration_number(existing_migrations)}_#{name}.exs")
      create_file file, EEx.eval_string(template, [mod: Module.concat([repo, Migrations, camelize(name)])])
      shell_info "Migration file #{file} has been added.", config
    end
  end

  defp padded_timestamp({{y, m, d}, {hh, mm, ss}}), do: "#{y}#{pad(m)}#{pad(d)}#{pad(hh)}#{pad(mm)}#{pad(ss)}"
  defp pad(i) when i < 10, do: << ?0, ?0 + i >>
  defp pad(i), do: to_string(i)

  defp migrations do
    templates_path = :coherence_oauth2
                     |> Application.app_dir
                     |> Path.join("priv/templates/migrations")

    for filename <- File.ls!(templates_path) do
      {String.slice(filename, 0..-5), File.read!(Path.join(templates_path, filename))}
    end
  end

  ################
  # Installer Configuration

  defp do_config(opts, []) do
    do_config(opts, list_to_atoms(@default_options))
  end
  defp do_config(opts, bin_opts) do
    binding = Mix.Project.config
    |> Keyword.fetch!(:app)
    |> Atom.to_string
    |> Mix.Phoenix.inflect

    base = opts[:module] || binding[:base]
    opts = Keyword.put(opts, :base, base)
    repo = Coherence.Config.repo
    web_path = opts[:web_path] || Mix.Phoenix.web_path(Mix.Phoenix.otp_app())

    binding = Keyword.put binding, :base, base

    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:web_path, web_path)
    |> Map.put(:instructions, "")
    |> Map.put(:base, base)
    |> Map.put(:opts, bin_opts)
    |> Map.put(:binding, binding)
    |> Map.put(:module, opts[:module])
    |> Map.put(:installed_options, opts[:installed_options])
    |> Map.put(:repo, repo)
    |> Map.put(:migration_path, opts[:migration_path])
    |> Map.put(:silent, opts[:silent])
    |> do_default_config(opts)
  end

  defp parse_options(opts) do
    {opts_bin, opts} = reduce_options(opts)
    opts_bin = Enum.uniq(opts_bin)
    opts_names = Enum.map opts, &(elem(&1, 0))

    with  [] <- Enum.filter(opts_bin, &(not &1 in @switch_names)),
          [] <- Enum.filter(opts_names, &(not &1 in @switch_names)) do
            {opts_bin, opts}
    else
      list -> raise_option_errors(list)
    end
  end
  defp reduce_options(opts) do
    Enum.reduce opts, {[], []}, fn
      {:default, true}, {acc_bin, acc} ->
        {list_to_atoms(@default_options) ++ acc_bin, acc}
      {name, true}, {acc_bin, acc} when name in @all_options_atoms ->
        {[name | acc_bin], acc}
      {name, false}, {acc_bin, acc} when name in @all_options_atoms ->
        {acc_bin -- [name], acc}
      opt, {acc_bin, acc} ->
        {acc_bin, [opt | acc]}
    end
  end

  defp print_installed_options(config) do
    ["mix coherence_oauth2.install"]
    |> list_config_options(Application.get_env(:coherence_oauth2, :opts, []))
    |> Enum.reverse
    |> Enum.join(" ")
    |> shell_info(config)
  end

  defp shell_info(_message, %{silent: true} = config), do: config
  defp shell_info(message, config) do
    Mix.shell.info message
    config
  end

  defp list_config_options(acc, opts) do
    opts
    |> Enum.reduce(acc, &config_option/2)
  end

  defp config_option(opt, acc) do
    str = opt
    |> Atom.to_string
    |> String.replace("_", "-")
    ["--" <> str | acc]
  end

  defp lib_path(path) do
    Path.join ["lib", to_string(Mix.Phoenix.otp_app()), path]
  end
end
