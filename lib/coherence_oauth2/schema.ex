defmodule CoherenceOauth2.Schema do
  @moduledoc """
  Add CoherenceOauth2 support to a User schema module.

  Add `use CoherenceOauth2.Schema` to your User module to add a number of
  Module functions and helpers.

  The `coherence_oauth2_schema/0` macro is used to add schema fields to the User models schema.

  ## Examples:
      defmodule MyProject.User do
        use MyProject.Web, :model

        use Coherence.Schema
        use CoherenceOauth2.Schema

        schema "users" do
          field :name, :string
          field :email, :string
          coherence_schema
          coherence_oauth2_schema
          timestamps
        end

        @required_fields ~w(name email)
        @optional_fields ~w() ++ coherence_fields

        def changeset(model, params \\ %{}) do
          model
          |> cast(params, @required_fields, @optional_fields)
          |> unique_constraint(:email)
          |> validate_coherence_oauth2(params)
        end

        def changeset(model, params, :password) do
          model
          |> cast(params, ~w(password password_confirmation reset_password_token reset_password_sent_at))
          |> validate_coherence_password_reset(params)
        end
      end
  """
  defmacro __using__(_opts \\ []) do
    quote do
      import unquote(__MODULE__)

      alias CoherenceOauth2.UserIdentities.UserIdentity

      def validate_coherence_oauth2(changeset, %{"user_identity_provider" => provider, "user_identity_uid" => uid} = params) do
        user_identity = %UserIdentity{provider: provider, uid: uid}

        changeset
        |> Ecto.Changeset.change(%{confirmed_at: Ecto.DateTime.utc, confirmation_token: nil})
        |> Ecto.Changeset.put_assoc(:user_identities, [user_identity])
      end
      def validate_coherence_oauth2(changeset, params) do
        user = changeset.data
               |> CoherenceOauth2.repo.preload(:user_identities)

        authenticatable_with_identities = Coherence.Config.has_option(:authenticatable) &&
                                          length(user.user_identities) > 0
        validate_coherence_oauth2(changeset,
                                  params,
                                  authenticatable_with_identities)
      end

      defp validate_coherence_oauth2(%{data: %{password_hash: nil}} = changeset, _params, true),
        do: changeset
      defp validate_coherence_oauth2(changeset, params, _authenticatable_with_identities),
        do: validate_coherence(changeset, params)
    end
  end

  @doc """
  Add configure schema fields.
  """
  defmacro coherence_oauth2_schema do
    quote do
      has_many :user_identities, CoherenceOauth2.UserIdentities.UserIdentity, foreign_key: :user_id
    end
  end
end
