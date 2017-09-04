defmodule CoherenceOauth2.RegistrationController do
  @moduledoc false
  use Coherence.Web, :controller

  def add_email(conn, params) do
    raise get_session(conn, "coherence_oauth2_params")
    # user_schema = Config.user_schema
    # cs = Helpers.changeset(:registration, user_schema, user_schema.__struct__)
    # render(conn, :new, email: "", changeset: cs)
  end
end
