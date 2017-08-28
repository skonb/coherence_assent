defmodule CoherenceOauth2.Callback do
  @doc false
  defp handler(conn, current_user, provider) do
    {:ok, current_user}
    |> check_current_user
    |> get_or_create_user(params)
  end

  @doc false
  def check_current_user({:ok, nil}, _), do: {:ok, nil}
  def check_current_user({:ok, current_user}, params) do
    case UserIdentity.create_identity(user, params) do
      {:ok, user_identity} -> {:ok, current_user}
      {:error, _}          -> {:error, :bound_to_different_user}
    end
  end

  @doc false
  defp get_or_create_user({:ok, nil}, params) do
    case UserIdentities.get_user_from_identity(params) do
      nil   -> insert_user_with_identity(params)
      user  -> {:ok, user}
    end
  end
  defp get_or_create_user({:ok, current_user}, _), do: {:ok, current_user}
  defp get_or_create_user({:error, _} = error, _), do: error

  @doc false
  defp insert_user_with_identity(%{email: email} = params) do
    user_schema = Config.user_schema
    :registration
    |> Controller.changeset(user_schema, user_schema.__struct__, registration_params)
    |> Schemas.create
    |> confirm! # Always confirm
    |> case do
  end
  defp insert_user_with_identity(params),
    do: {:error, :missing_email}
  end


    @doc false
    defp confirm!({:ok, user}) do
      unless ConfirmableService.confirmed? user do
        changeset = ConfirmableService.confirm(user)
        Config.repo.update changeset
      else
        {:ok, user}
      end
    end
    defp confirm!(error = {:error, _}), do: error

end
