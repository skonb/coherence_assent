defmodule CoherenceOauth2.Github do
  use OAuth2.Strategy

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

  def authorize_url!(client, params \\ []) do
    params = Keyword.merge(params, [scope: "user,user:email"])

    OAuth2.Client.authorize_url!(client, params)
  end

  def get_user(client, headers \\ [], params \\ []) do
    client
    |> OAuth2.Client.get("/user", headers, params)
    |> normalize_with_email(client)
  end

  defp normalize_with_email({:ok, %OAuth2.Response{body: user}}, client) do
    case OAuth2.Client.get(client, "/user/emails") do
      {:ok, %OAuth2.Response{body: emails}} ->
        {:ok, %{
          "uid"      => Integer.to_string(user["id"]),
          "nickname" => user["login"],
          "email"    => get_primary_email(emails),
          "name"     => user["name"],
          "image"    => user["avatar_url"],
          "urls"     => %{
            "GitHub" => user["html_url"],
            "Blog"   => user["blog"]
          }
        }}
      {:error, _} = response -> response
    end
  end
  defp normalize_with_email(response, _client), do: response

  defp get_primary_email(emails) do
    emails
    |> Enum.find(%{}, fn(element) -> element["primary"] && element["verified"] end)
    |> Map.fetch("email")
    |> case do
      {:ok, email} -> email
      :error       -> nil
    end
  end
end
