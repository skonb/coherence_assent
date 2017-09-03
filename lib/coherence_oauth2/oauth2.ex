defmodule CoherenceOauth2.Oauth2 do
  @doc false
  defp get_config!(provider) do
    case CoherenceOauth2.config(provider) do
      nil     -> raise "No matching provider configuration available for #{provider}"
      options -> options
    end
  end

  @doc false
  def authorize_url!(provider, params \\ []) do
    provider
    |> build_client
    |> OAuth2.Client.authorize_url!(params)
  end

  @doc false
  def get_user!(provider, code) do
    provider
    |> build_client()
    |> OAuth2.Client.get_token!(code: code)
    |> get_user_from_handler!(provider)
  end

  defp get_handler(config, provider) do
    config[:handler] || raise "No :handler set for :#{provider} configuration!"
  end

  @doc false
  defp build_client(provider) do
    config = get_config!(provider)

    config
    |> get_handler(provider)
    |> apply(:client, [config])
  end

  defp get_user_from_handler!(client, provider) do
    config = get_config!(provider)

    config
    |> get_handler(provider)
    |> apply(:get_user!, [client])
  end
end
