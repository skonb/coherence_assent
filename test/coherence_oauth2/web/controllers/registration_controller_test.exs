defmodule CoherenceOauth2.RegistrationControllerTest do
  use CoherenceOauth2.Test.ConnCase

  import CoherenceOauth2.Test.Fixture
  import OAuth2.TestHelpers

  @provider "test_provider"

  setup %{conn: conn} do
    conn =  conn
    |> session_conn()
    |> Plug.Conn.put_session(:coherence_oauth2_params, %{"uid" => "1", "name" => "John Doe"})

    {:ok, conn: conn}
  end

  test "add_login_field/2 shows", %{conn: conn} do
    conn = get conn, coherence_oauth2_registration_path(conn, :add_login_field, @provider)
    assert html_response(conn, 200)
  end

  test ":create/2 shows", %{conn: conn} do
    conn = post conn, coherence_oauth2_registration_path(conn, :create, @provider), %{email: "foo@example.com"}

    assert redirected_to(conn) == Coherence.ControllerHelpers.logged_in_url(conn)
    assert [new_user] = CoherenceOauth2.repo.all(CoherenceOauth2.Test.User)
    assert new_user.email == "foo@example.com"
    refute CoherenceOauth2.Test.User.confirmed?(new_user)
  end
end
