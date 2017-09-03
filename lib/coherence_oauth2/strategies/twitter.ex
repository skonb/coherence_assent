defmodule CoherenceOauth2.Twitter do
  def client(config) do
    [
      strategy: OAuth2.Strategy.AuthCode,
      site: "https://api.twitter.com",
      authorize_url: "/oauth/authenticate"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def get_user!(client) do
    client
    |> OAuth2.Client.get!("/1.1/account/verify_credentials.json?include_entities=false&skip_status=true&include_email=true")
    |> apply(:body)
    |> normalize
  end

  defp normalize(map) do
    %{
      "uid"      => map["user_id"],
      "nickname" => map["screen_name"],
      "email"    => map["email"],
      "location" => map["location"],
      "name"     => map["name"],
      "image"    => map["profile_image_url_https"],
      "descriptin" => map["description"],
      "urls"     => %{
        "Website" => map["url"],
        "Twitter"   => "https://twitter.com/#{map["screen_name"]}"
      }
    }
  end
end
