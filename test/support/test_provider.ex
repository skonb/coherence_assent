defmodule TestProvider do
  def client(config) do
    [
      strategy: OAuth2.Strategy.AuthCode,
      site: "http://localhost:4000/",
      authorize_url: "/oauth/authorize",
      token_url: "/oauth/token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def get_user!(client) do
    OAuth2.Client.get!(client, "/api/user").body
  end
end
