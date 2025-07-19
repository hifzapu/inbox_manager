defmodule InboxManager.Categories.Category do
  use Ecto.Schema
  import Ecto.Changeset

  schema "categories" do
    field :name, :string
    field :description, :string
    belongs_to :user, InboxManager.User

    timestamps()
  end

  @doc false
  def changeset(category, attrs) do
    category
    |> cast(attrs, [:name, :description, :user_id])
    |> validate_required([:name, :user_id])
    |> unique_constraint(:name)
    |> foreign_key_constraint(:user_id)
  end
end
