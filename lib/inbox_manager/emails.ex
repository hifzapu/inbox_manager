defmodule InboxManager.Emails do
  @moduledoc """
  The Emails context.
  """

  import Ecto.Query, warn: false
  alias InboxManager.Repo
  alias InboxManager.Emails.Email

  @doc """
  Returns the list of emails.
  """
  def list_emails do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        preload: [category: c],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails filtered by category.
  """
  def list_emails_by_category(category_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        where: e.category_id == ^category_id,
        preload: [category: c],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Gets a single email.
  """
  def get_email!(id), do: Repo.get!(Email, id)

  @doc """
  Creates a email.
  """
  def create_email(attrs \\ %{}) do
    %Email{}
    |> Email.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a email.
  """
  def update_email(%Email{} = email, attrs) do
    email
    |> Email.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a email.
  """
  def delete_email(%Email{} = email) do
    Repo.delete(email)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email changes.
  """
  def change_email(%Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs)
  end
end
