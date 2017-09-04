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
        user = %{
          name: "Dan Schultzer",
          email: "foo@example.com",
          id: "1"
        }
        Plug.Conn.resp(conn, 200, Poison.encode!(user))
      end

      expected = %{
        "descriptin" => nil,
        "email" => "foo@example.com",
        "first_name" => nil,
        "image" => "http://localhost:#{bypass.port}/1/picture",
        "last_name" => nil,
        "location" => nil,
        "name" => "Dan Schultzer",
        "nickname" => nil,
        "uid" => "1",
        "urls" => %{"Facebook" => nil,
                    "Website" => nil},
        "verified" => nil}

      assert {:ok, expected} == CoherenceOauth2.Facebook.get_user(client)
    end
  end
end
