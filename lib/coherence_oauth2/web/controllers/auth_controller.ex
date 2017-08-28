defmodule CoherenceOauth2.AuthController do
  @moduledoc false
  use CoherenceOauth2.Web, :controller

  import CoherenceOauth2

  alias Coherence.Controller
  alias CoherenceOauth2.Oauth2
  alias CoherenceOauth2.Callback

  def index(conn, %{"provider" => provider}) do
    client = Oauth2.get_client!(provider)

    redirect conn, external: authorize_url!(client)
  end

  def callback(conn, %{"provider" => provider, "code" => code}) do
    client = Oauth2.get_client!(provider)
    token  = Oauth2.get_token!(client, code: code)
    params = Oauth2.get_user!(client, token)

    case Callback.handler(conn, Coherence.current_user(conn), provider) do
      {:error, :bound_to_different_user} -> conn
                                            |> put_flash(:alert, "The %{provider} account is already bound to another user.")
                                            |> redirect_to(:session_create)
      {:error, :missing_email}           -> conn
                                            |> redirect_to(:registration_add_email, params)
      {:ok, user}                        -> Controller.login_user(conn, user)
                                            |> redirect_to(:session_create, params)
    end
  end
end
