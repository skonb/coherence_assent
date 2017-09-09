defmodule CoherenceAssent.GoogleTest do
  use CoherenceAssent.TestCase

  import OAuth2.TestHelpers

  setup do
    bypass = Bypass.open
    client = CoherenceAssent.Google.client(site: bypass_server(bypass),
                                             token: %OAuth2.AccessToken{
                                               access_token: "token"
                                              })

    {:ok, client: client, bypass: bypass}
  end

  describe "get_user/2" do
    test "normalizes data", %{client: client, bypass: bypass} do
      Bypass.expect_once bypass, "GET", "/people/me/openIdConnect", fn conn ->
        user = %{"kind" => "plus#personOpenIdConnect",
                 "gender" => "",
                 "sub" => "1",
                 "name" => "Dan Schultzer",
                 "given_name" => "Dan",
                 "family_name" => "Schultzer",
                 "profile" => "https://example.com/profile",
                 "picture" => "https://example.com/images/profile.jpg",
                 "email" => "foo@example.com",
                 "email_verified" => "true",
                 "locale" => "en-US",
                 "hd" => "example.com"}
        Plug.Conn.resp(conn, 200, Poison.encode!(user))
      end

      expected = %{"email" => "foo@example.com",
                   "image" => "https://example.com/images/profile.jpg",
                   "name" => "Dan Schultzer",
                   "first_name" => "Dan",
                   "last_name" => "Schultzer",
                   "domain" => "example.com",
                   "uid" => "1",
                   "urls" => %{"Google" => "https://example.com/profile"}}

      assert {:ok, expected} == CoherenceAssent.Google.get_user(client)
    end
  end
end
