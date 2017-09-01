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
    * Update User model installed by Coherence.
    * Generate appropriate migration files.
    * Generate appropriate template files.
  ## Examples
      mix coherence_oauth2.install
  # ## Option list
  #   * Your Coherence user model will be modifiedunless the `--no-update-coherence` option is given.
  #   * A `--config-file config/config.exs` option can be given to change what config file to append to.
  #   * A `--installed-options` option to list the previous install options.
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
    migration_path: :string
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
    |> update_coherence_files
    |> gen_coherence_oauth2_templates
    |> gen_migration_files
    |> print_instructions
  end

  defp validate_option(_, :all), do: true
  defp validate_option(%{opts: opts}, opt) do
    if opt in opts, do: true, else: false
  end

  ##################
  # Coherence Update

  defp update_coherence_files(%{update_coherence: true} = config) do
    user_path = lib_path("coherence/user.ex")
    case File.lstat(user_path) do
      {:ok, %{type: :regular}} -> update_user_model(user_path)
                                  config
      _ -> Mix.raise "Cannot find Coherence user model at #{user_path}"
    end
  end
  defp update_coherence_files(config), do: config

  defp update_user_model(user_path) do
    File.read!(user_path)
    |> add_after_in_user_model("use Coherence.Schema", "use CoherenceOauth2.Schema")
    |> add_after_in_user_model("coherence_schema()", "coherence_oauth2_schema()")
    |> replace_in_user_model("|> validate_coherence(params)", "|> validate_coherence_oauth2(params)")
    |> update_user_model_file(user_path)
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

  defp update_user_model_file(content, path) do
    {:ok, file} = File.open path, [:write]
    IO.binwrite file, content
    File.close file
  end

  ################
  # Templates

  @template_files [
    registration: {:registration, ~w(add_email)}
  ]

  defp gen_coherence_oauth2_templates(%{templates: true, boilerplate: true, binding: binding} = config) do
    for {name, {opt, files}} <- @template_files do
      if validate_option(config, opt), do: copy_templates(binding, name, files)
    end
    config
  end
  defp gen_coherence_oauth2_templates(config), do: config

  defp copy_templates(binding, name, file_list) do
    Mix.Phoenix.copy_from paths(),
      "priv/boilerplate/templates/#{name}", binding, copy_templates_files(name, file_list)
  end
  defp copy_templates_files(name, file_list) do
    for fname <- file_list do
      fname = "#{fname}.html.eex"
      {:eex, fname, web_path("templates/coherence_oauth2/#{name}/#{fname}")}
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

  defp print_instructions(%{instructions: instructions} = config) do
    Mix.shell.info instructions
    Mix.shell.info router_instructions(config)
    Mix.shell.info migrate_instructions(config)

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
    path =
     case config[:migration_path] do
       path when is_binary(path) -> path
       _                         -> migrations_path(repo)
     end

    create_directory path
    existing_migrations = to_string File.ls!(path)

    for {name, template} <- migrations() do
      create_migration_file(repo, existing_migrations, name, path, template)
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

  defp create_migration_file(repo, existing_migrations, name, path, template) do
    unless String.match? existing_migrations, ~r/\d{14}_#{name}\.exs/ do
      file = Path.join(path, "#{next_migration_number(existing_migrations)}_#{name}.exs")
      create_file file, EEx.eval_string(template, [mod: Module.concat([repo, Migrations, camelize(name)])])
      Mix.shell.info "Migration file #{file} has been added."
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

    binding = Keyword.put binding, :base, base
    binding = Keyword.put binding, :web_prefix, web_path("")

    bin_opts
    |> Enum.map(&({&1, true}))
    |> Enum.into(%{})
    |> Map.put(:instructions, "")
    |> Map.put(:base, base)
    |> Map.put(:opts, bin_opts)
    |> Map.put(:binding, binding)
    |> Map.put(:module, opts[:module])
    |> Map.put(:installed_options, opts[:installed_options])
    |> Map.put(:repo, repo)
    |> Map.put(:migration_path, opts[:migration_path])
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

  defp print_installed_options(_config) do
    ["mix coherence_oauth2.install"]
    |> list_config_options(Application.get_env(:coherence_oauth2, :opts, []))
    |> Enum.reverse
    |> Enum.join(" ")
    |> Mix.shell.info
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

  defp web_path(path), do: Path.join(get_web_prefix(), path)
  defp get_web_prefix do
    case :erlang.function_exported(Mix.Phoenix, :web_path, 2) do
      # Above 1.3.0.rc otp_app is passed as a symbol
      true -> Mix.Phoenix.otp_app() |> Mix.Phoenix.web_path()
      _ -> Mix.Phoenix.web_path("")
    end
  end

  defp lib_path(path) do
    Path.join ["lib", to_string(Mix.Phoenix.otp_app()), path]
  end
end
