defmodule CoherenceOauth2.Controller do
  use Coherence.Web, :controller

  import Plug.Conn, only: [put_session: 3]
  import CoherenceOauth2.Oauth2, only: [dgettext: 3]


  def callback_response({:ok, user}, conn, _provider, _params) do
    conn
    |> Coherence.ControllerHelpers.login_user(user)
    |> redirect_to(:session_create, %{})
  end
  def callback_response({:error, :bound_to_different_user}, conn, _provider, _params) do
    conn
    |> put_flash(:alert, "The %{provider} account is already bound to another user.")
    |> redirect_to_router_path(:registration_path, :new)
  end
  def callback_response({:error, :missing_login_field}, conn, provider, params) do
    conn
    |> put_session("coherence_oauth2_params", params)
    |> redirect_to_router_path(:coherence_oauth2_registration_path, :add_login_field, [provider])
  end
  def callback_response({:error, error}, conn, provider, params) do
    login_field = Coherence.Config.login_field

    case error do
      %{errors: [{^login_field, {"has already been taken", _}}]} ->
        conn = put_flash(conn, :alert, dgettext("coherence", "%{login_field} is used by another user.", login_field: Phoenix.Naming.humanize(login_field)))
        callback_response({:error, :missing_login_field}, conn, provider, params)
      %{errors: errors} ->
        raise errors
    end
  end

  defp redirect_to_router_path(conn, path, action, params \\ []) do
    path = apply(router_helpers(), path, [conn, action] ++ params)
    redirect(conn, to: path)
  end
end
