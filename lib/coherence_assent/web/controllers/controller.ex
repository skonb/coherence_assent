defmodule CoherenceAssent.Controller do
  use Coherence.Web, :controller

  import Plug.Conn, only: [put_session: 3]
  import Phoenix.Naming, only: [humanize: 1]

  def get_config!(provider) do
    config = provider |> CoherenceAssent.config()

    config
    |> case do
         nil  -> nil
         list -> Enum.into(list, %{})
       end
    |> case do
         %{strategy: _} -> config
         %{}            -> raise "No :strategy set for :#{provider} configuration!"
         nil            -> raise "No provider configuration available for #{provider}."
       end
  end

  def call_strategy!(config, method, arguments) do
    apply(config[:strategy], method, arguments)
  end

  def callback_response({:ok, :user_created, user}, conn, _provider, _user_params, _params) do
    conn
    |> send_confirmation(user)
    |> Coherence.ControllerHelpers.login_user(user)
    |> redirect_to(:registration_create, %{})
  end
  def callback_response({:ok, _type, user}, conn, _provider, _user_params, _params) do
    conn
    |> Coherence.ControllerHelpers.login_user(user)
    |> redirect_to(:session_create, %{})
  end
  def callback_response({:error, :bound_to_different_user}, conn, provider, _user_params, _params) do
    conn
    |> put_flash(:alert, CoherenceAssent.messages(:account_already_bound_to_other_user, %{provider: humanize(provider)}))
    |> redirect(to: get_route(conn, :registration_path, :new))
  end
  def callback_response({:error, :missing_login_field}, conn, provider, user_params, _params) do
    conn
    |> put_session("coherence_assent_params", user_params)
    |> redirect(to: get_route(conn, :coherence_assent_registration_path, :add_login_field, [provider]))
  end
  def callback_response({:error, %Ecto.Changeset{} = changeset}, conn, _provider, user_params, params) do
    login_field = Coherence.Config.login_field

    case changeset do
      %{errors: [{^login_field, _}]} = changeset ->
        conn
        |> put_session("coherence_assent_params", user_params)
        |> CoherenceAssent.RegistrationController.add_login_field(params, changeset)
      %{errors: _errors} ->
        conn
        |> put_flash(:alert,  CoherenceAssent.messages(:could_not_sign_in))
        |> redirect(to: get_route(conn, :registration_path, :new))
    end
  end

  def get_route(conn, path, action, params \\ []) do
    apply(router_helpers(), path, [conn, action] ++ params)
  end

  defp send_confirmation(conn, user) do
    case Coherence.Config.user_schema.confirmed?(user) do
      false -> Coherence.ControllerHelpers.send_confirmation(conn, user, Coherence.Config.user_schema)
      _     -> conn
    end
  end
end
