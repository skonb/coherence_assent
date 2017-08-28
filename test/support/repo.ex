defmodule CoherenceOauth2.Test.Repo do
  use Ecto.Repo, otp_app: :coherence_oauth2

  def log(_cmd), do: nil
end
