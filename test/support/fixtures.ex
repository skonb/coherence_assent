defmodule CoherenceOauth2.Test.Fixture do
  alias CoherenceOauth2.Test.Repo
  alias CoherenceOauth2.Test.User

  def fixture(:user, attrs \\ %{}) do
    {:ok, user} = %User{}
    |> Map.merge(%{email: "user@example.com"})
    |> Map.merge(attrs)
    |> Repo.insert

    user
  end
end
