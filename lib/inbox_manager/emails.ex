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
        left_join: ga in assoc(e, :gmail_account),
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails for a specific user (across all their Gmail accounts).
  """
  def list_emails_by_user(user_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: ga.user_id == ^user_id,
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails directly associated with a user (using user_id field).
  """
  def list_emails_by_user_direct(user_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: e.user_id == ^user_id,
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails for a specific Gmail account.
  """
  def list_emails_by_gmail_account(gmail_account_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: e.gmail_account_id == ^gmail_account_id,
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @spec list_emails_by_category(any()) :: any()
  @doc """
  Returns the list of emails filtered by category.
  """
  def list_emails_by_category(category_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: e.category_id == ^category_id,
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails filtered by category for a specific user.
  """
  def list_emails_by_category_and_user(category_id, user_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: e.category_id == ^category_id and ga.user_id == ^user_id,
        preload: [category: c, gmail_account: ga],
        order_by: [desc: e.inserted_at]
    )
  end

  @doc """
  Returns the list of emails filtered by category for a specific user (using user_id field directly).
  """
  def list_emails_by_category_and_user_direct(category_id, user_id) do
    Repo.all(
      from e in Email,
        left_join: c in assoc(e, :category),
        left_join: ga in assoc(e, :gmail_account),
        where: e.category_id == ^category_id and e.user_id == ^user_id,
        preload: [category: c, gmail_account: ga],
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
  Deletes multiple emails by their IDs.
  """
  def delete_emails_by_ids(email_ids) when is_list(email_ids) do
    from(e in Email, where: e.id in ^email_ids)
    |> Repo.delete_all()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking email changes.
  """
  def change_email(%Email{} = email, attrs \\ %{}) do
    Email.changeset(email, attrs)
  end
end
