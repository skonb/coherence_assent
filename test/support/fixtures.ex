defmodule CoherenceOauth2.Test.Fixture do
  alias CoherenceOauth2.Test.Repo
  alias CoherenceOauth2.Test.User
  alias CoherenceOauth2.UserIdentities.UserIdentity

  def fixture(:user, attrs \\ %{}) do
    {:ok, user} = %User{}
    |> Map.merge(%{email: "user@example.com"})
    |> Map.merge(attrs)
    |> Repo.insert

    user
  end
  def fixture(:user_identity, user, attrs) do
    {:ok, identity} = %UserIdentity{user: user}
    |> Map.merge(%{provider: "test_provider", uid: "1"})
    |> Map.merge(attrs)
    |> Repo.insert

    identity
  end
end
