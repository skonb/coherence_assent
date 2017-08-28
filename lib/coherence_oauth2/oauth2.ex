defmodule CoherenceOauth2.Oauth2 do
  @doc false
  defp get_client!(provider) do
    Keyword.get(CoherenceOauth2.config(), provider)
    case Keyword.get(CoherenceOauth2.config(provider), provider) do
      nil    -> raise "No matching provider available"
      client -> client
    end
  end

  @doc false
  def authorize_url!(client, params \\ []) do
    OAuth2.Client.authorize_url!(params)
  end

  @doc false
  def get_token!(client, params \\ [], headers \\ []) do
    OAuth2.Client.get_token!(client, params, headers)
  end

  @doc false
  def get_user!(client, token) do
    OAuth2.AccessToken.get!(client, user_uri(client))
  end

  @doc false
  defp user_uri(client) do
    client[:user_uri] || raise "No :user_uri has been set for provider"
  end
end
