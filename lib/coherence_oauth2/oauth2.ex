defmodule CoherenceOauth2.Oauth2 do
  require Logger

  @doc false
  def authorize_url!(provider, params \\ []) do
    call_handler!(provider, :authorize_url!, [build_client(provider), params])
  end

  @doc false
  def get_user!(provider, code) do
    client = get_client_with_access_token(provider, code)

    provider
    |> call_handler!(:get_user, [client])
    |> process_get_user_response(provider)
  end

  defp process_get_user_response({:ok, user}, _provider), do: user
  defp process_get_user_response({:error, %OAuth2.Response{status_code: 401, body: body}}, _provider) do
    raise "Unauthorized token"
    Logger.error("Unauthorized token")
  end
  defp process_get_user_response({:error, %OAuth2.Error{reason: reason}}, _provider) do
    raise reason
    Logger.error("Error: #{inspect reason}")
  end

  defp get_client_with_access_token(provider, code) do
    client = build_client(provider)

    client
    |> OAuth2.Client.get_token!(code: code, client_secret: client.client_secret)
    |> case do
         %{token: %{other_params: %{"error" => error, "error_description" => error_description }}} ->
          raise error_description
         %{token: %{access_token: nil}} ->
          raise "No access token."
         %{token: _token} = client ->
          client
       end
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

    config
    |> get_handler(provider)
    |> apply(:client, [config])
  end

  defp call_handler!(provider, method, arguments) do
    config = get_config!(provider)

    config
    |> get_handler(provider)
    |> apply(method, arguments)
  end

  def dgettext(_domain, msg, _opts \\ %{}), do: msg
end
