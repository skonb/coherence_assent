defmodule CoherenceOauth2.UserIdentities do
  @moduledoc """
  The boundary for the OauthAccessGrants system.
  """

  import Ecto.{Query, Changeset}, warn: false
  alias CoherenceOauth2.UserIdentities.UserIdentity

  @doc """
  Gets a single access grant registered with an application.

  ## Examples

      iex> get_grant_for("github", "uid")
      %User{}

      iex> get_grant_for("github", "invalid_uid")
      ** nil

  """
  def get_user_from_identity_params(provider, uid) do
    UserIdentity
    |> CoherenceOauth2.repo.get_by(provider: provider, uid: uid)
    |> get_user_from_identity
  end

  defp get_user_from_identity(nil), do: nil
  defp get_user_from_identity(identity) do
    identity
    |> CoherenceOAuth2.repo.preload(:user)
    |> apply(:user)
  end

  @doc """
  Creates a new user identity.

  ## Examples

      iex> create_identity(user, params)
      {:ok, %OauthAccessGrant{}}

      iex> create_identity(user, params)
      {:error, %Ecto.Changeset{}}

  """
  def create_identity(%{id: _} = user, provider, uid) do
    %UserIdentity{user: user}
    |> new_identity_changeset(%{provider: provider, uid: uid})
    |> CoherenceOauth2.repo.insert()
  end

  defp new_identity_changeset(%UserIdentity{} = identity, params) do
    identity
    |> cast(params, [:provider, :uid])
    |> assoc_constraint(:user)
    |> validate_required([:provider, :uid, :user])
    |> unique_constraint(:uid_provider, name: :user_identities_uid_provider_index)
  end
end
