defmodule CoherenceAssent.Twitter do
  alias CoherenceAssent.StrategyHelpers, as: Helpers

  def client(config) do
    [
      site: "https://api.twitter.com",
      authorize_url: "/oauth/authenticate",
      token_url: "/oauth2/token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def authorize_url!(client, params \\ []),
    do: OAuth2.Client.authorize_url!(client, params)

  def get_user(client) do
    client
    |> OAuth2.Client.get("/1.1/account/verify_credentials.json?include_entities=false&skip_status=true&include_email=true")
    |> normalize
  end

  defp normalize({:ok, %OAuth2.Response{body: user}}) do
    {:ok, %{"uid"      => Integer.to_string(user["id"]),
            "nickname" => user["screen_name"],
            "email"    => user["email"],
            "location" => user["location"],
            "name"     => user["name"],
            "image"    => user["profile_image_url_https"],
            "description" => user["description"],
            "urls"     => %{"Website" => user["url"],
                            "Twitter"   => "https://twitter.com/#{user["screen_name"]}"}
          } |> Helpers.prune}
  end
  defp normalize(response), do: response
end
