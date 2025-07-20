defmodule InboxManager.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string
    belongs_to :user, InboxManager.Users.User

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> foreign_key_constraint(:user_id)
  end
end
