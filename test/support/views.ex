defmodule CoherenceOauth2.CoherenceOauth2View do
  use CoherenceOauth2.Test.CoherenceOauth2.Web, :view
end
defmodule CoherenceOauth2.LayoutView do
  use CoherenceOauth2.Test.CoherenceOauth2.Web, :view
end
defmodule CoherenceOauth2.Test.ErrorView do
  def render("500.html", _changeset), do: "500.html"
  def render("400.html", _changeset), do: "400.html"
  def render("404.html", _changeset), do: "404.html"
end
