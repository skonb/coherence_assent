defmodule CoherenceAssent.Test.Web.Gettext do
  use Gettext, otp_app: :coherence_assent
end

defmodule CoherenceAssent.Test.Coherence.ViewHelpers do
  use Phoenix.HTML

  @spec required_label(atom, String.t | atom, Keyword.t) :: tuple
  def required_label(f, name, opts \\ []) do
    label f, name, opts do
      [
        "#{humanize(name)}\n",
        content_tag(:abbr, "*", class: "required", title: "required")
      ]
    end
  end
end

defmodule CoherenceAssent.Test.Web.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  use Phoenix.HTML

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn (error) ->
      content_tag :span, translate_error(error), class: "help-block"
    end)
  end

  @doc """
  Translates an error message using gettext.
  """
  def translate_error({msg, _opts}), do: msg
end


defmodule CoherenceAssent.Test.Web do
  def view do
    quote do
      use Phoenix.View, root: "tmp/coherence/web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import CoherenceAssent.Test.Web.Gettext
      import CoherenceAssent.Test.Web.ErrorHelpers
      import CoherenceAssent.Test.Web.Router.Helpers
      import CoherenceAssent.Test.Coherence.ViewHelpers
    end
  end
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
