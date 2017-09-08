defmodule CoherenceOauth2.RegistrationController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Callback
  import Plug.Conn, only: [get_session: 2, delete_session: 2]
  alias CoherenceOauth2.Controller
  import CoherenceOauth2.Oauth2, only: [dgettext: 2]

  def add_login_field(conn, %{"provider" => _provider} = params) do
    user_schema = Config.user_schema
    changeset = Coherence.ControllerHelpers.changeset(:registration, user_schema, user_schema.__struct__)

    add_login_field(conn, params, changeset)
  end
  def add_login_field(conn, %{"provider" => provider}, changeset) do
    conn
    |> check_session
    |> case do
         {:error, conn} -> conn
         {:ok, conn, _params} ->
           conn
           |> put_view(get_view_module(["Coherence", "RegistrationView"]))
           |> put_layout({get_view_module(["LayoutView"]), :app})
           |> render(:add_login_field, changeset: changeset, provider: provider)
       end
  end

  def create(conn, %{"provider" => provider, "registration" => registration} = params) do
    conn
    |> check_session
    |> case do
         {:error, conn} -> conn
         {:ok, conn, coherence_oauth2_params} ->
           login_field = Atom.to_string(Coherence.Config.login_field)

           user_params = coherence_oauth2_params
           |> Map.put("unconfirmed", true)
           |> Map.put(login_field, Map.get(registration, login_field))

           conn
           |> delete_session("coherence_oauth2_params")
           |> Coherence.current_user()
           |> Callback.handler(provider, user_params)
           |> Controller.callback_response(conn, provider, user_params, params)
       end
  end

  defp check_session(conn) do
    case get_session(conn, :coherence_oauth2_params) do
      nil ->
        conn = conn
        |> put_flash(:alert, no_session_data_found())
        |> Controller.get_route(:registration_path, :new)

        {:error, conn}

      session_data ->
        {:ok, conn, session_data}
    end
  end

  defp get_view_module(modules) do
    :coherence
    |> Application.get_env(:web_module)
    |> Module.concat(Module.concat(modules))
  end

  defp no_session_data_found(),
    do: dgettext("coherence_oauth2", "No session data found.")
end
