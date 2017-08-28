defmodule CoherenceOauth2 do
  @doc false
  def config() do
    Application.get_env(:coherence_oauth2, CoherenceOauth2, [])
  end
end
