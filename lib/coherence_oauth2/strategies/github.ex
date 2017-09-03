defmodule CoherenceOauth2.Github do
  def client(config) do
    [
      strategy: OAuth2.Strategy.AuthCode,
      site: "https://api.github.com",
      authorize_url: "https://github.com/login/oauth/authorize",
      token_url: "https://github.com/login/oauth/access_token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def get_user!(client) do
    client
    |> OAuth2.Client.get!("user")
    |> apply(:body)
    |> normalize
  end

  defp normalize(map) do
    %{
      "uid"      => map["id"],
      "nickname" => map["login"],
      "email"    => map["email"],
      "name"     => map["name"],
      "image"    => map["avatar_url"],
      "urls"     => %{
        "GitHub" => map["html_url"],
        "Blog"   => map["blog"]
      }
    }
  end
end
