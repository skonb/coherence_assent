defmodule CoherenceOauth2.Test.Router do
  use Phoenix.Router
  use Coherence.Router
  use CoherenceOauth2.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :public do
    plug Coherence.Authentication.Session
  end

  pipeline :protected do
    plug Coherence.Authentication.Session, protected: true
  end

  scope "/" do
    pipe_through [:browser, :public]
    coherence_routes()
    coherence_oauth2_routes()
  end

  scope "/" do
    pipe_through [:browser, :protected]
    coherence_routes :protected
  end
end
