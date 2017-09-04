defmodule CoherenceOauth2.GithubTest do
  use CoherenceOauth2.TestCase

  import OAuth2.TestHelpers

  setup do
    bypass = Bypass.open

    client = CoherenceOauth2.Github.client(site: bypass_server(bypass))

    {:ok, client: client, bypass: bypass}
  end

  describe "get_user/2" do
    test "normalizes data", %{client: client, bypass: bypass} do
      Bypass.expect_once bypass, "GET", "/user", fn conn ->
        user = %{
          login: "octocat",
          id: 1,
          avatar_url: "https://github.com/images/error/octocat_happy.gif",
          gravatar_id: "",
          url: "https://api.github.com/users/octocat",
          html_url: "https://github.com/octocat",
          followers_url: "https://api.github.com/users/octocat/followers",
          following_url: "https://api.github.com/users/octocat/following{/other_user}",
          gists_url: "https://api.github.com/users/octocat/gists{/gist_id}",
          starred_url: "https://api.github.com/users/octocat/starred{/owner}{/repo}",
          subscriptions_url: "https://api.github.com/users/octocat/subscriptions",
          organizations_url: "https://api.github.com/users/octocat/orgs",
          repos_url: "https://api.github.com/users/octocat/repos",
          events_url: "https://api.github.com/users/octocat/events{/privacy}",
          received_events_url: "https://api.github.com/users/octocat/received_events",
          type: "User",
          site_admin: false,
          name: "monalisa octocat",
          company: "GitHub",
          blog: "https://github.com/blog",
          location: "San Francisco",
          email: "octocat@github.com",
          hireable: false,
          bio: "There once was...",
          public_repos: 2,
          public_gists: 1,
          followers: 20,
          following: 0,
          created_at: "2008-01-14T04:33:35Z",
          updated_at: "2008-01-14T04:33:35Z"
        }
        Plug.Conn.resp(conn, 200, Poison.encode!(user))
      end

      Bypass.expect_once bypass, "GET", "/user/emails", fn conn ->
        emails = [
                    %{
                      email: "octocat@github.com",
                      verified: true,
                      primary: true,
                      visibility: "public"
                    }
                  ]
        Plug.Conn.resp(conn, 200, Poison.encode!(emails))
      end

      expected = %{
        "email" => "octocat@github.com",
        "image" => "https://github.com/images/error/octocat_happy.gif",
        "name" => "monalisa octocat",
        "nickname" => "octocat",
        "uid" => "1",
        "urls" => %{
          "Blog" => "https://github.com/blog",
          "GitHub" => "https://github.com/octocat"
        }
      }

      assert {:ok, expected} == CoherenceOauth2.Github.get_user(client)
    end
  end
end
