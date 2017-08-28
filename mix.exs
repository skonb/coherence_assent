defmodule CoherenceOauth2.Mixfile do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :coherence_oauth2,
      version: @version,
      elixir: "~> 1.3",
      elixirc_paths: elixirc_paths(Mix.env),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      preferred_cli_env: [credo: :test, ex_doc: :test],
      deps: deps(),

      # Hex
      description: "OAuth 2 client support for Coherence",
      package: package(),

       # Docs
       name: "CoherenceOauth2",
       docs: [source_ref: "v#{@version}", main: "CoherenceOauth2",
              canonical: "http://hexdocs.pm/coherence_oauth2",
              source_url: "https://github.com/danschultzer/coherence_oauth2",
              extras: ["README.md"]]
    ]
  end

  def application do
    [
      extra_applications: extra_applications(Mix.env)
    ]
  end

  defp extra_applications(:test), do: [:postgrex, :ecto, :logger]
  defp extra_applications(_), do: [:logger]

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:coherence, "~> 0.5.0"},
      {:oauth2, "~> 0.9"},
      {:ecto, "~> 2.1"},

      # Dev and test dependencies
      {:credo, "~> 0.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.14", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Dan Shultzer"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/danschultzer/coherence_oauth2"},
      files: ~w(lib priv/templates) ++ ~w(LICENSE mix.exs README.md)
    ]
  end
end
