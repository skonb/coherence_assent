defmodule CoherenceOauth2 do
  @doc false
  def config() do
    Application.get_env(:coherence_oauth2, CoherenceOauth2, [])
  end

  @doc false
  def config(provider) do
    clients()[String.to_atom(provider)]
  end

  @doc false
  def repo, do: Coherence.Config.repo

  @doc false
  def clients do
    Application.get_env(:coherence_oauth2, :providers) || raise "CoherenceOauth2 is missing the :providers configration!"
  end
end
