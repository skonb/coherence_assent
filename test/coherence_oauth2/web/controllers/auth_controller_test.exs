defmodule CoherenceOauth2.AuthControllerTest do
  use CoherenceOauth2.Test.ConnCase

  import CoherenceOauth2.Test.Fixture

  @index_params %{provider: "github"}
  @callback_params %{provider: "github", uid: "test"}

  setup %{conn: conn} do
    user = fixture(:user)
    {:ok, conn: conn, user: user}
  end

  test "index/2 redirects to authorization url", %{conn: conn} do
    conn = get conn, auth_path(conn, :index, @index_params)

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
  end

  test "callback/2 with current_user", %{conn: conn, user: user} do
    conn = conn
    |> assign conn, :current_user, user
    |> get conn, auth_path(conn, :callback, @index_params)

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
  end

  test "callback/2 with current_user and identity bound to another user", %{conn: conn, user: user} do
    diff_user = fixture(:user, email: "anotheruser@example.com")
    identity = fixture(:user_identity, differ_user)

    conn = conn
    |> assign conn, :current_user, user
    |> get conn, auth_path(conn, :callback, @callback_params)

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
  end

  test "callback/2 with missing oauth email", %{conn: conn} do
    conn = get conn, auth_path(conn, :callback, @callback_params)

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
    # check not signed in
  end

  test "callback/2 with an exesting registered user", %{conn: conn} do
    conn = get conn, auth_path(conn, :callback, Map.merge(@callback_params, %{email: user.email}))

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
    # check not signed in
  end

  test "callback/2", %{conn: conn} do
    conn = get conn, auth_path(conn, :callback, Map.merge(@callback_params, %{email: "diff@example.com"}))

    assert redirected_to(conn) == "https://example.com?error=unsupported_response_type&error_description=The+authorization+server+does+not+support+this+response+type."
    # check created user
    # check signed in
  end
end
