defmodule CoherenceOauth2.RegistrationControllerTest do
  use CoherenceOauth2.Test.ConnCase

  import CoherenceOauth2.Test.Fixture

  @provider "test_provider"

  setup %{conn: conn} do
    conn = conn
    |> session_conn()
    |> Plug.Conn.put_session(:coherence_oauth2_params, %{"uid" => "1", "name" => "John Doe"})

    {:ok, conn: conn}
  end

  test "add_login_field/2 shows", %{conn: conn} do
    conn = get conn, coherence_oauth2_registration_path(conn, :add_login_field, @provider)
    assert html_response(conn, 200)
  end

  test "create/2 with valid", %{conn: conn} do
    conn = post conn, coherence_oauth2_registration_path(conn, :create, @provider), %{registration: %{email: "foo@example.com"}}

    assert redirected_to(conn) == Coherence.ControllerHelpers.logged_in_url(conn)
    assert [new_user] = CoherenceOauth2.repo.all(CoherenceOauth2.Test.User)
    assert new_user.email == "foo@example.com"
    refute CoherenceOauth2.Test.User.confirmed?(new_user)
  end

  test "create/2 with taken login_field", %{conn: conn} do
    fixture(:user, %{email: "foo@example.com"})

    conn = post conn, coherence_oauth2_registration_path(conn, :create, @provider), %{registration: %{email: "foo@example.com"}}

    assert html_response(conn, 200) =~ "has already been taken"
  end

  test "create/2 with invalid login_field", %{conn: conn} do
    conn = post conn, coherence_oauth2_registration_path(conn, :create, @provider), %{registration: %{email: "foo"}}

    assert html_response(conn, 200) =~ "has invalid format"
  end
end
