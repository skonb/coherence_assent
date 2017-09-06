defmodule CoherenceOauth2.SchemaTest do
  use CoherenceOauth2.TestCase

  import CoherenceOauth2.Test.Fixture

  setup do
    {:ok, user: fixture(:user), params: %{name: "John Doe", password: "new_password", password_confirmation: "new_password"}}
  end

  describe "changeset/1" do
    test "doesn't have error with identity and no password", %{user: user, params: params} do
      fixture(:user_identity, user, %{provider: "test_provider", uid: "1"})

      changeset = CoherenceOauth2.Test.User.changeset(user, params)
      assert changeset.valid?
    end

    test "has error with no password", %{user: user, params: params} do
      changeset = CoherenceOauth2.Test.User.changeset(user, params)
      refute changeset.valid?
    end
  end
end
