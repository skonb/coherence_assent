defmodule CoherenceOauth2.AuthController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Oauth2
  alias CoherenceOauth2.Callback
  import Plug.Conn, only: [put_session: 3]

  def index(conn, %{"provider" => provider}) do
    redirect conn, external: Oauth2.authorize_url!(provider)
  end

  def callback(conn, %{"provider" => provider, "code" => code}) do
    user_params = Oauth2.get_user!(provider, code)

    Coherence.current_user(conn)
    |> Callback.handler(provider, user_params)
    |> callback_response(conn, provider, user_params)
  end

  defp callback_response({:ok, user}, conn, _provider, _params) do
    conn
    |> Coherence.ControllerHelpers.login_user(user)
    |> redirect_to(:session_create, %{})
  end
  defp callback_response({:error, :bound_to_different_user}, conn, _provider, _params) do
    conn
    |> put_flash(:alert, "The %{provider} account is already bound to another user.")
    |> redirect_to_router_path(:registration_path, :new)
  end
  defp callback_response({:error, :missing_email}, conn, provider, params) do
    conn
    |> put_session("coherence_oauth2_params", params)
    |> redirect_to_router_path(:coherence_oauth2_registration_path, :add_email, [provider])
  end
  defp callback_response({:error, %Ecto.Changeset{errors: [email: {"has already been taken", _}]}}, conn, provider, params) do
    conn = put_flash(conn, :alert, "E-mail is used by another user.")

    callback_response({:error, :missing_email}, conn, provider, params)
  end
  defp callback_response({:error, %Ecto.Changeset{errors: errors}}, conn, _provider, _params) do
    raise errors
  end

  defp redirect_to_router_path(conn, path, action, params \\ []) do
    path = apply(router_helpers(), path, [conn, action] ++ params)
    redirect(conn, to: path)
  end
end
