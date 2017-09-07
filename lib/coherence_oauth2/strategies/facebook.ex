defmodule CoherenceOauth2.Facebook do
  alias CoherenceOauth2.StrategyHelpers, as: Helpers

  def client(config) do
    [
      site: "https://graph.facebook.com/v2.6",
      authorize_url: "https://www.facebook.com/v2.6/dialog/oauth",
      token_url: "/oauth/access_token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def authorize_url!(client, params \\ []) do
    params = Keyword.merge(params, [scope: "email"])

    OAuth2.Client.authorize_url!(client, params)
  end

  def get_user(client) do
    client
    |> OAuth2.Client.put_param(:appsecret_proof, appsecret_proof(client))
    |> OAuth2.Client.put_param(:fields, "name,email")
    |> OAuth2.Client.get("/me")
    |> normalize(client)
  end

  defp normalize({:ok, %OAuth2.Response{body: user}}, client) do
    {:ok, %{"uid"      => user["id"],
            "nickname" => user["username"],
            "email"    => user["email"],
            "name"     => user["name"],
            "first_name" => user["first_name"],
            "last_name" => user["last_name"],
            "location" => (user["location"] || %{})["name"],
            "image"    => image_url(client, user),
            "description" => user["bio"],
            "urls"     => %{"Facebook" => user["link"],
                            "Website"   => user["website"]},
            "verified" => user["verified"]}
          |> Helpers.prune}
  end
  defp normalize(response, _client), do: response

  defp image_url(client, user) do
    "#{client.site}/#{user["id"]}/picture"
  end

  defp appsecret_proof(client) do
    :sha256
    |> :crypto.hmac(client.client_secret, client.token.access_token)
    |> Base.encode16
  end
end
