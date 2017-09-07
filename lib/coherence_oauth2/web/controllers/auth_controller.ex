defmodule CoherenceOauth2.AuthController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Oauth2
  alias CoherenceOauth2.Callback
  alias CoherenceOauth2.Controller

  def index(conn, %{"provider" => provider}) do
    redirect conn, external: Oauth2.authorize_url!(provider)
  end

  def callback(conn, %{"provider" => provider, "code" => code}) do
    user_params = Oauth2.get_user!(provider, code)

    Coherence.current_user(conn)
    |> Callback.handler(provider, user_params)
    |> Controller.callback_response(conn, provider, user_params)
  end
end
