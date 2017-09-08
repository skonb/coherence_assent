defmodule CoherenceOauth2.AuthController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Oauth2
  alias CoherenceOauth2.Callback
  alias CoherenceOauth2.Controller

  def index(conn, %{"provider" => provider}) do
    redirect conn, external: Oauth2.authorize_url!(provider, redirect_uri: redirect_uri(conn, provider))
  end

  def callback(conn, %{"provider" => provider, "code" => code} = params) do
    user_params = Oauth2.get_user!(provider, code, redirect_uri(conn, provider))

    Coherence.current_user(conn)
    |> Callback.handler(provider, user_params)
    |> Controller.callback_response(conn, provider, user_params, params)
  end

  defp redirect_uri(conn, provider) do
    Controller.get_route(conn, :coherence_oauth2_auth_url, :callback, [provider])
  end
end
