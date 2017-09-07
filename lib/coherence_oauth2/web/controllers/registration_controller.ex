defmodule CoherenceOauth2.RegistrationController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Callback
  import Plug.Conn, only: [get_session: 2, delete_session: 2]
  alias CoherenceOauth2.Controller
  import CoherenceOauth2.Oauth2, only: [dgettext: 2]

  def add_login_field(conn, %{"provider" => provider}) do
    conn
    |> check_session
    |> case do
         {:error, conn} -> conn
         {:ok, conn, _params} ->
           user_schema = Config.user_schema
           changeset = Coherence.ControllerHelpers.changeset(:registration, user_schema, user_schema.__struct__)

           conn
           |> set_registration_view
           |> render(:add_login_field, changeset: changeset, provider: provider)
       end
  end

  def create(conn, %{"provider" => provider} = params) do
    conn
    |> check_session
    |> case do
         {:error, conn} -> conn
         {:ok, conn, coherence_oauth2_params} ->
           delete_session(conn, :coherence_oauth2_params)

           login_field = Atom.to_string(Coherence.Config.login_field)

           user_params = coherence_oauth2_params
           |> Map.put_new(login_field, params[login_field])

           conn
           |> Coherence.current_user()
           |> Callback.handler(provider, user_params)
           |> Controller.callback_response(conn, provider, user_params)
       end
  end

  defp check_session(conn) do
    case get_session(conn, :coherence_oauth2_params) do
      nil ->
        conn = conn
        |> put_flash(:alert, no_session_data_found())
        |> redirect_to(:session_create, %{})
        #CoherenceOauth2.AuthController.redirect_to_router_path(:registration_path, :new)
        {:error, conn}

      session_data ->
        {:ok, conn, session_data}
    end
  end

  defp set_registration_view(conn) do
    module = :coherence
             |> Application.get_env(:web_module)
             |> Module.concat(Module.concat(["Coherence", "RegistrationView"]))

    conn
    |> put_view(module)
  end

  defp no_session_data_found(),
    do: dgettext("coherence_oauth2", "No session data found.")
end
