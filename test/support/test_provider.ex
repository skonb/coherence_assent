defmodule TestProvider do
  alias CoherenceOauth2.StrategyHelpers, as: Helpers

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

  def authorize_url!(client, params \\ []) do
    client
    |> OAuth2.Client.authorize_url!(params)
  end

  def get_user(client) do
    OAuth2.Client.get(client, "/api/user")
    |> normalize
  end

  defp normalize({:ok, %OAuth2.Response{body: map}}) do
    {:ok, %{"uid"      => map["uid"],
            "name"     => map["name"],
            "email"    => map["email"]}
          |> Helpers.prune}
  end
  defp normalize({:error, _} = response), do: response

end
