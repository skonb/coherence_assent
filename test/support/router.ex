defmodule CoherenceOauth2.Test.Router do
  use Phoenix.Router
  use CoherenceOauth2.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/" do
    coherence_oauth2_routes
  end
end
