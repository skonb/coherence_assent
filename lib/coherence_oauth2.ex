defmodule CoherenceOauth2 do
  @doc false
  def config() do
    Application.get_env(:coherence_oauth2, CoherenceOauth2, [])
  end

  @doc false
  def config(provider) do
    Application.get_env(:coherence_oauth2, String.to_atom(provider), nil)
  end

  @doc false
  def repo, do: Coherence.Config.repo
end
