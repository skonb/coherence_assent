defmodule CoherenceOauth2.Router do
  @moduledoc """
  Handles routing for CoherenceOauth2.

  ## Usage

  Configure `lib/my_project/web/router.ex` the following way:

      defmodule MyProject.Router do
        use MyProjectWeb, :router
        use CoherenceOauth2.Router

        scope "/", MyProjectWeb do
          pipe_through :browser

          coherence_oauth2_routes
        end

        ...
      end
  """

  alias CoherenceOauth2.Oauth2Controller

  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)
    end
  end

  @doc """
  CoherenceOauth2 router macro.
  Use this macro to define the CoherenceOauth2 routes.

  ## Examples:
      scope "/" do
        coherence_oauth2_routes
      end
  """
  defmacro coherence_oauth2_routes(mode, options \\ %{}) do
    quote location: :keep do
      mode = unquote(mode)
      options = Map.merge(%{scope: "auth"}, unquote(Macro.escape(options)))

      scope "/#{options[:scope]}", as: "auth" do
        get "/:provider", AuthController, :index
        get "/:provider/callback", AuthController, :callback
      end
    end
  end
end
