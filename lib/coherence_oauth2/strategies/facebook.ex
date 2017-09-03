defmodule CoherenceOauth2.Facebook do
  def client(config) do
    [
      strategy: OAuth2.Strategy.AuthCode,
      site: "https://graph.facebook.com/v2.6",
      authorize_url: "https://www.facebook.com/v2.6/dialog/oauth",
      token_url: "oauth/access_token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def get_user!(client) do
    client
    |> OAuth2.Client.get!("me")
    |> apply(:body)
    |> normalize
  end

  defp normalize(map) do
    %{
      "uid"      => map["id"],
      "nickname" => map["screen_name"],
      "email"    => map["email"],
      "name"     => map["name"],
      "first_name" => map["first_name"],
      "last_name" => map["last_name"],
      "location" => map["location"]["name"],
      "image"    => map["profile_image_url_https"],
      "descriptin" => map["bio"],
      "urls"     => %{
        "Facebook" => map["link"],
        "Website"   => map["website"]
      },
      "verified" => map["verified"]
    }
  end
end
