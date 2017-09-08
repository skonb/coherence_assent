defmodule CoherenceOauth2.Oauth2 do
  require Logger

  @doc false
  def authorize_url!(provider, params \\ []) do
    call_handler(provider, :authorize_url!, [build_client(provider), params])
  end

  @doc false
  def get_user(provider, code, redirect_uri) do
    provider
    |> get_client_with_access_token(code, redirect_uri)
    |> process_access_token_response
    |> get_user_from_access_token(provider)
  end

  defp process_access_token_response({:ok, %{token: %{other_params: %{"error" => error, "error_description" => error_description }}}}, _provider),
    do: {:error, %CoherenceOauth2.RequestError{message: error_description, error: error}}
  defp process_access_token_response({:ok, client}),
    do: {:ok, client}
  defp process_access_token_response({:error, %OAuth2.Response{body: %{"error" => error}}}),
    do: {:error, %CoherenceOauth2.RequestError{message: error}}
  defp process_access_token_response({:error, error}),
    do: {:error, error}

  defp get_user_from_access_token({:ok, client}, provider) do
    provider
    |> call_handler(:get_user, [client])
    |> process_user_response(provider)
  end
  defp get_user_from_access_token({:error, _} = error, provider), do: error

  defp process_user_response({:ok, user}, _provider), do: {:ok, user}
  defp process_user_response({:error, %OAuth2.Response{status_code: 401, body: body}}, _provider) do
    raise "Unauthorized token"
    Logger.error("Unauthorized token")
  end
  defp process_user_response({:error, %OAuth2.Error{reason: reason}}, _provider) do
    raise reason
    Logger.error("Error: #{inspect reason}")
  end

  defp get_client_with_access_token(provider, code, redirect_uri) do
    provider
    |> build_client()
    |> get_token(code, redirect_uri)
  end

  defp get_token(client, code, redirect_uri) do
    OAuth2.Client.get_token(client,
                            code: code,
                            client_secret: client.client_secret,
                            redirect_uri: redirect_uri)
  end

  defp get_config!(provider) do
    case CoherenceOauth2.config(provider) do
      nil     -> raise "No matching provider configuration available for #{provider}."
      options -> options
    end
  end

  defp get_handler(config, provider) do
    config[:handler] || raise "No :handler set for :#{provider} configuration!"
  end

  @doc false
  defp build_client(provider) do
    config = get_config!(provider)
    call_handler(provider, :client, [config])
  end

  defp call_handler(provider, method, arguments) do
    config = get_config!(provider)

    config
    |> get_handler(provider)
    |> apply(method, arguments)
  end

  def dgettext(_domain, msg, _opts \\ %{}), do: msg
end
