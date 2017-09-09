defmodule CoherenceAssent.Strategy.Facebook do
  alias CoherenceAssent.Strategy.Helpers
  alias CoherenceAssent.Strategies.Oauth2, as: Oauth2Helper

  def authorize_url(conn: conn, config: config) do
    config = config |> set_config
    Oauth2Helper.authorize_url(conn: conn, config: config)
  end

  def callback(conn: conn, config: config, params: %{"code" => code, "redirect_uri" => redirect_uri} = params) do
    config = config |> set_config
    client = config |> OAuth2.Client.new()

    {:ok, %{conn: conn, client: client}}
    |> Oauth2Helper.check_conn(params)
    |> Oauth2Helper.get_access_token(params)
    |> get_user(config)
    |> normalize()
  end

  defp set_config(config) do
    [
      site: "https://graph.facebook.com/v2.6",
      authorize_url: "https://www.facebook.com/v2.6/dialog/oauth",
      token_url: "/oauth/access_token",
      user_url: "/me",
      authorization_params: ["email"],
      user_url_request_fields: "name,email"
    ]
    |> Keyword.merge(config)
    |> Keyword.put(:strategy, OAuth2.Strategy.AuthCode)
  end

  defp get_user({:ok, %{conn: conn, client: client}}, config) do
    client = client
    |> OAuth2.Client.put_param(:appsecret_proof, appsecret_proof(client))
    |> OAuth2.Client.put_param(:fields, config[:user_url_request_fields])

    Oauth2Helper.get_user({:ok, %{conn: conn, client: client}}, config)
  end
  defp get_user({:error, _} = error, _config), do: error

  defp normalize({:ok, %{conn: conn, client: client, user: user}}) do
    user = %{"uid"         => user["id"],
             "nickname"    => user["username"],
             "email"       => user["email"],
             "name"        => user["name"],
             "first_name"  => user["first_name"],
             "last_name"   => user["last_name"],
             "location"    => (user["location"] || %{})["name"],
             "image"       => image_url(client, user),
             "description" => user["bio"],
             "urls"        => %{"Facebook" => user["link"],
                                "Website"  => user["website"]},
             "verified"    => user["verified"]}
           |> Helpers.prune

    {:ok, %{conn: conn, client: client, user: user}}
  end
  defp normalize({:error, _} = error), do: error

  defp image_url(client, user) do
    "#{client.site}/#{user["id"]}/picture"
  end

  defp appsecret_proof(client) do
    :sha256
    |> :crypto.hmac(client.client_secret, client.token.access_token)
    |> Base.encode16
  end
end
