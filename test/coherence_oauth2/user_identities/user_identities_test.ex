defmodule CoherenceOauth2.UserIdentitiesTest do
  use CoherenceOauth2.TestCase

  import CoherenceOauth2.Test.Fixture

  alias CoherenceOauth.UserIdentities
  alias ExOauth2Provider.OauthAccessGrants.OauthAccessGrant

  @valid_attrs    %{provider: "facebook", uid: "token"}

  setup do
    {:ok, %{user: fixture(:user)}}
  end

  test "get_user_from_identity_params/2", %{user: user} do
    {:ok, identity} = UserIdentities.create_identity(user, @valid_attrs)
    assert %UserIdentities.UserIdentity{id: id} = get_user_from_identity_params("facebook", "token")
    assert identity.id == id
  end

  test "create_identity/3 with valid attributes", %{user: user} do
    assert {:ok, %UserIdentities.UserIdentity{} = identity} = UserIdentities.create_identity(user, @valid_attrs)
    assert identity.user == user
  end
end
