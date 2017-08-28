defmodule CoherenceOauth2.UserIdentities.UserIdentities do
  @moduledoc false

  use Ecto.Schema

  schema "oauth_access_grants" do
    belongs_to :user, Coherence.Config.user_schema.__struct__

    field :provider,     :string,     null: false
    field :uid,          :string,    null: false

    timestamps(updated_at: false)
  end
end
