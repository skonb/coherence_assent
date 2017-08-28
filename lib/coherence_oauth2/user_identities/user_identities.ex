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
    |> CoherenceOauth2.repo.get_one(provider: provider, uid: uid)
    |> Ecto.assoc(:user)
    |> CoherenceOauth2.repo.one
  end

  @doc """
  Creates a new user identity.

  ## Examples

      iex> create_identity(user, params)
      {:ok, %OauthAccessGrant{}}

      iex> create_identity(user, params)
      {:error, %Ecto.Changeset{}}

  """
  def create_identity(%{id: _} = user, params) do
    %UserIdentity{user: user}
    |> new_identity_changeset(params)
    |> CoherenceOauth2.repo.insert()
  end

  defp new_identity_changeset(%UserIdentity{} = identity, params) do
    identity
    |> cast(params, [:provider, :uid])
    |> assoc_constraint(:user)
    |> validate_required([:provider, :uid, :user])
    |> unique_constraint(:uid, name: :user_identitites_uid_provider_index)
  end
end
