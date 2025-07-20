defmodule InboxManager.Categories do
  @moduledoc """
  The Categories context.
  """

  import Ecto.Query, warn: false
  alias InboxManager.Repo
  alias InboxManager.Categories.Category

  @doc """
  Returns the list of vehicles.
  """
  def list_categories(user_id) do
    Repo.all(from c in Category, where: c.user_id == ^user_id)
  end

  @doc """
  Gets a single user.
  """
  def get_category!(id), do: Repo.get!(Category, id)

  @doc """
  Gets a category by name and user_id.
  """
  def get_category_by_name(name, user_id) do
    from(c in Category,
      where: c.user_id == ^user_id and fragment("LOWER(?)", c.name) == ^String.downcase(name)
    )
    |> Repo.one()
  end

  @doc """
  Creates a user.
  """
  def create_category(attrs \\ %{}) do
    %Category{}
    |> Category.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a user.
  """
  def update_category(%Category{} = category, attrs) do
    category
    |> Category.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a user.
  """
  def delete_category(%Category{} = category) do
    Repo.delete(category)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.
  """
  def change_category(%Category{} = category, attrs \\ %{}) do
    Category.changeset(category, attrs)
  end
end
