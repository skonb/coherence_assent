defmodule CoherenceOauth2.Test.CoherenceOauth2.Web do
  def view do
    quote do
      use Phoenix.View, root: "tmp/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import CoherenceOauth2.Test.Router.Helpers

      # Add view helpers including routes helpers
      import CoherenceOauth2.ViewHelpers
    end
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
