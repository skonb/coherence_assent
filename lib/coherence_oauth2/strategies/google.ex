defmodule CoherenceOauth2.Google do
  alias CoherenceOauth2.StrategyHelpers, as: Helpers

  def client(config) do
    [
      site: "https://www.googleapis.com/plus/v1",
      authorize_url: "https://accounts.google.com/o/oauth2/auth",
      token_url: "https://accounts.google.com/o/oauth2/token"
    ]
    |> Keyword.merge(config)
    |> OAuth2.Client.new()
  end

  def authorize_url!(client, params \\ []) do
    params = Keyword.merge(params, [scope: "email profile"])

    OAuth2.Client.authorize_url!(client, params)
  end

  def get_user(client) do
    client
    |> OAuth2.Client.get("/people/me/openIdConnect")
    |> normalize
  end

  defp normalize({:ok, %OAuth2.Response{body: user}}) do
    {:ok, %{"uid"        => user["sub"],
            "name"       => user["name"],
            "email"      => verified_email(user),
            "first_name" => user["given_name"],
            "last_name"  => user["family_name"],
            "image"      => user["picture"],
            "domain"     => user["hd"],
            "urls"       => %{"Google" => user["profile"]}}
          |> Helpers.prune}
  end
  defp normalize(response), do: response

  defp verified_email(%{"email_verified" => "true"} = user), do: user["email"]
  defp verified_email(_), do: nil
end
