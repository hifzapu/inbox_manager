defmodule InboxManager.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :email, :string
    field :first_name, :string
    field :last_name, :string
    field :location, :string
    field :image, :string
    field :provider, :string
    field :token, :string
    field :refresh_token, :string
    field :last_known_history_id, :string
    field :token_expires_at, :integer

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [
      :email,
      :first_name,
      :last_name,
      :location,
      :image,
      :provider,
      :token,
      :refresh_token,
      :last_known_history_id,
      :token_expires_at
    ])
    |> validate_required([:email])
    |> unique_constraint(:email)
  end
end
