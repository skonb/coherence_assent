defmodule CoherenceOauth2.AuthControllerTest do
  use CoherenceOauth2.Test.ConnCase

  import CoherenceOauth2.Test.Fixture
  import OAuth2.TestHelpers

  @provider "test_provider"
  @callback_params %{code: "test"}

  setup %{conn: conn} do
    server = Bypass.open

    Application.put_env(:coherence_oauth2, :clients, [
                          test_provider: [
                            client_id: "client_id",
                            client_secret: "abc123",
                            site: bypass_server(server),
                            redirect_uri: "#{bypass_server(server)}/auth/callback",
                            handler: TestProvider
                          ]
                        ])

    user = fixture(:user)
    {:ok, conn: conn, user: user, server: server}
  end

  test "index/2 redirects to authorization url", %{conn: conn, server: server} do
    conn = get conn, coherence_oauth2_auth_path(conn, :index, @provider)

    assert redirected_to(conn) == "http://localhost:#{server.port}/oauth/authorize?client_id=client_id&redirect_uri=http%3A%2F%2Flocalhost%3A#{server.port}%2Fauth%2Fcallback&response_type=code"
  end

  describe "callback/2" do
    test "with current_user session", %{conn: conn, server: server, user: user} do
      bypass_oauth(server)

      conn = conn
      |> assign(Coherence.Config.assigns_key, user)
      |> get(coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params))

      assert redirected_to(conn) == Coherence.ControllerHelpers.logged_in_url(conn)
      assert length(get_user_identities()) == 1
    end

    test "with current_user session and identity bound to another user", %{conn: conn, server: server, user: user} do
      bypass_oauth(server)
      fixture(:user_identity, user, %{provider: @provider, uid: "1"})

      conn = conn
      |> assign(Coherence.Config.assigns_key, user)
      |> get(coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params))

      assert redirected_to(conn) == "/registrations/new"
      assert get_flash(conn, :alert) == "The %{provider} account is already bound to another user."
    end

    test "with valid params", %{conn: conn, server: server, user: user} do
      bypass_oauth(server, %{}, %{email: "newuser@example.com"})

      conn = get conn, coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params)

      assert redirected_to(conn) == Coherence.ControllerHelpers.logged_in_url(conn)
      assert [new_user] = get_user_identities()
      refute new_user.user_id == user.id
    end

    test "with missing oauth email", %{conn: conn, server: server} do
      bypass_oauth(server)

      conn = get conn, coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params)

      assert redirected_to(conn) == "/auth/test_provider/add_email"
      assert length(get_user_identities()) == 0
      assert Plug.Conn.get_session(conn, "coherence_oauth2_params") == %{"email" => nil, "name" => "Dan Schultzer", "uid" => "1"}
    end

    test "with an existing different registered user email", %{conn: conn, server: server, user: user} do
      bypass_oauth(server, %{}, %{email: user.email})

      conn = get conn, coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params)

      assert redirected_to(conn) == "/auth/test_provider/add_email"
      assert length(get_user_identities()) == 0
      assert get_flash(conn, :alert) == "E-mail is used by another user."
      assert Plug.Conn.get_session(conn, "coherence_oauth2_params") == %{"email" => "user@example.com", "name" => "Dan Schultzer", "uid" => "1"}
    end

    test "with valid params and existing user identity", %{conn: conn, server: server, user: user} do
      bypass_oauth(server, %{}, %{email: user.email})

      fixture(:user_identity, user, %{provider: @provider, uid: "1"})

      conn = get conn, coherence_oauth2_auth_path(conn, :callback, @provider, @callback_params)

      assert redirected_to(conn) == Coherence.ControllerHelpers.logged_in_url(conn)
    end

    defp bypass_oauth(server, token_params \\ %{}, user_params \\ %{}) do
      bypass server, "POST", "/oauth/token", fn conn ->
        send_resp(conn, 200, Poison.encode!(Map.merge(%{access_token: "access_token"}, token_params)))
      end

      bypass server, "GET", "/api/user", fn conn ->
        send_resp(conn, 200, Poison.encode!(Map.merge(%{uid: "1", name: "Dan Schultzer"}, user_params)))
      end
    end

    defp get_user_identities do
      CoherenceOauth2.UserIdentities.UserIdentity
      |> CoherenceOauth2.repo.all
    end
  end
end
