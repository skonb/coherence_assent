defmodule CoherenceOauth2.Callback do
  alias CoherenceOauth2.UserIdentities
  alias Coherence.ControllerHelpers, as: Helpers
  alias Coherence.Schemas

  @doc false
  def handler(current_user, provider, params) do
    {:ok, current_user}
    |> check_current_user(provider, params)
    |> get_or_create_user(provider, params)
  end

  @doc false
  defp check_current_user({:ok, nil}, _provider, _params), do: {:ok, nil}
  defp check_current_user({:ok, current_user}, provider, %{"uid" => uid}) do
    case UserIdentities.create_identity(current_user, provider, uid) do
      {:ok, _user_identity}                  -> {:ok, current_user}
      {:error, %{errors: [uid_provider: _]}} -> {:error, :bound_to_different_user}
      {:error, error}                        -> {:error, error}
    end
  end

  @doc false
  defp get_or_create_user({:ok, nil}, provider, %{"uid" => uid} = params) do
    case UserIdentities.get_user_from_identity_params(provider, uid) do
      nil   -> insert_user_with_identity(params, provider, uid)
      user  -> {:ok, user}
    end
  end
  defp get_or_create_user({:ok, current_user}, _, _), do: {:ok, current_user}
  defp get_or_create_user({:error, _} = error, _, _), do: error

  @doc false
  defp insert_user_with_identity(%{"email" => _email} = registration_params, provider, uid) do
    user_schema = Coherence.Config.user_schema
    registration_params = registration_params
                          |> Map.merge(%{"user_identity_provider" => provider, "user_identity_uid" => uid})
    :registration
    |> Helpers.changeset(user_schema, user_schema.__struct__, registration_params)
    |> Schemas.create
  end
  defp insert_user_with_identity(_registration_params, _provider, _uid),
    do: {:error, :missing_email}
end
