defmodule CoherenceOauth2.FacebookTest do
  use CoherenceOauth2.TestCase

  import OAuth2.TestHelpers

  setup do
    bypass = Bypass.open
    client = CoherenceOauth2.Facebook.client(site: bypass_server(bypass),
                                             token: %OAuth2.AccessToken{
                                               access_token: "token"
                                             })

    {:ok, client: client, bypass: bypass}
  end

  describe "get_user/2" do
    test "normalizes data", %{client: client, bypass: bypass} do
      Bypass.expect_once bypass, "GET", "/me", fn conn ->
        user = %{name: "Dan Schultzer",
                 email: "foo@example.com",
                 id: "1"}
        Plug.Conn.resp(conn, 200, Poison.encode!(user))
      end

      expected = %{"email" => "foo@example.com",
                   "image" => "http://localhost:#{bypass.port}/1/picture",
                   "name" => "Dan Schultzer",
                   "uid" => "1",
                   "urls" => %{}}

      assert {:ok, expected} == CoherenceOauth2.Facebook.get_user(client)
    end
  end
end
