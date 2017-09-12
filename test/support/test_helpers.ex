defmodule OAuth2.TestHelpers do
  @moduledoc """
  OAuth server mock has been lifted from
  https://github.com/scrogson/oauth2/blob/master/test/support/test_helpers.ex
  """

  import Plug.Conn
  import ExUnit.Assertions

  def bypass_server(%Bypass{port: port}) do
    "http://localhost:#{port}"
  end

  def bypass(server, method, path, fun) do
    bypass(server, method, path, [], fun)
  end
  def bypass(server, method, path, opts, fun) do
    {token, _opts}   = Keyword.pop(opts, :token, nil)

    Bypass.expect_once server, method, path, fn conn ->
      conn = parse_req_body(conn)

      assert_token(conn, token)

      fun.(conn)
    end
  end

  defp parse_req_body(conn) do
    opts = [parsers: [:urlencoded, :json],
            pass: ["*/*"],
            json_decoder: Poison]
    Plug.Parsers.call(conn, Plug.Parsers.init(opts))
  end

  defp assert_token(_conn, nil), do: :ok
  defp assert_token(conn, token) do
    assert get_req_header(conn, "authorization") == ["Bearer #{token.access_token}"]
  end
end
