defmodule CoherenceOauth2.AuthController do
  @moduledoc false
  use Coherence.Web, :controller

  alias CoherenceOauth2.Oauth2
  alias CoherenceOauth2.Callback
  alias CoherenceOauth2.Controller

  def index(conn, %{"provider" => provider}) do
    state = gen_state()

    conn
    |> Plug.Conn.put_session("coherence_oauth2.state", state)
    |> redirect(external: Oauth2.authorize_url!(provider,
                                                redirect_uri: redirect_uri(conn, provider),
                                                state: state))
  end

  def callback(conn, %{"provider" => provider, "code" => code} = params) do
    conn
    |> check_state(params)
    |> get_user(code, provider)
    |> callback_handler(provider, params)
  end
  def callback(conn, params) do
    raise "error_reason"
  end

  defp redirect_uri(conn, provider) do
    Controller.get_route(conn, :coherence_oauth2_auth_url, :callback, [provider])
  end

  defp check_state(conn, %{"error" => _} = params) do
    {:error, %CoherenceOauth2.CallbackError{message: params["error_description"] || params["error_reason"] || params["error"], error: params["error"], error_uri: params["error_uri"]}, conn}
  end
  defp check_state(conn, %{"code" => _code} = params) do
    state = Plug.Conn.get_session(conn, "coherence_oauth2.state")
    conn = Plug.Conn.delete_session(conn, "coherence_oauth2.state")

    case params["state"] do
      ^state -> {:ok, conn}
      _      -> {:error, %CoherenceOauth2.CallbackCSRFError{}, conn}
    end
  end

  defp get_user({:ok, conn}, code, provider) do
    case Oauth2.get_user(provider, code, redirect_uri(conn, provider)) do
      {:ok, params}   -> {:ok, params, conn}
      {:error, error} -> {:error, error, conn}
    end
  end
  defp get_user({:error, _error, _conn} = error, _code, _provider), do: error

  defp callback_handler({:ok, user_params, conn}, provider, params) do
    conn
    |> Coherence.current_user()
    |> Callback.handler(provider, user_params)
    |> Controller.callback_response(conn, provider, user_params, params)
  end
  defp callback_handler({:error, error, _conn}, _provider, _params),
    do: raise error

  defp gen_state() do
    :crypto.strong_rand_bytes(24)
    |> :erlang.bitstring_to_list
    |> Enum.map(fn (x) -> :erlang.integer_to_binary(x, 16) end)
    |> Enum.join
    |> String.downcase
  end
end
