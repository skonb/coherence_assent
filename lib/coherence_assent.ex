defmodule CoherenceAssent do
  @doc false
  def config() do
    Application.get_env(:coherence_assent, CoherenceAssent, [])
  end

  @doc false
  def config(provider) do
    providers!()
    |> Keyword.get(String.to_atom(provider), nil)
  end

  @doc false
  def repo, do: Coherence.Config.repo

  @doc false
  def providers! do
    Application.get_env(:coherence_assent, :providers) || raise "CoherenceAssent is missing the :providers configuration!"
  end

  def messages(:could_not_sign_in),
    do: dgettext("coherence_assent", "Could not sign in. Please try again.")
  def messages(method),
    do: apply(Coherence.Messages.backend(), method)

  def messages(:account_already_bound_to_other_user, opts),
    do: dgettext("coherence_assent", "The %{provider} account is already bound to another user.", opts)
  def messages(method, opts),
    do: apply(Coherence.Messages.backend(), method, [opts])

  defp dgettext(domain, msg, opts \\ %{}),
    do: messages_backend().dgettext(domain, msg, opts)

  defp messages_backend() do
    config()
    |> Keyword.get(:messages_backend, nil)
    |> case do
         nil    -> Application.get_env(:coherence, :messages_backend)
         module -> module
       end
    |> Code.ensure_loaded()
    |> case do
         {:error, _}       -> raise "Please set the :messages_backend in the configuration"
         {:module, module} -> module
       end
  end

  defmodule CallbackError do
    defexception [:message, :error, :error_uri]
  end

  defmodule CallbackCSRFError do
    defexception message: "CSRF detected"
  end

  defmodule RequestError do
    defexception [:message, :error]
  end
end
