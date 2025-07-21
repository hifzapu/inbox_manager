defmodule InboxManager.GmailAccounts do
  @moduledoc """
  The GmailAccounts context.
  """

  import Ecto.Query, warn: false
  alias InboxManager.Repo
  alias InboxManager.GmailAccounts.GmailAccount

  @doc """
  Returns the list of gmail_accounts for a user.
  """
  def list_gmail_accounts(user_id) do
    Repo.all(from g in GmailAccount, where: g.user_id == ^user_id and g.is_active == true)
  end

  @doc """
  Returns the list of all active gmail_accounts across all users.
  """
  def list_all_active_gmail_accounts do
    Repo.all(from g in GmailAccount, where: g.is_active == true)
  end

  @doc """
  Gets a single gmail_account.
  """
  def get_gmail_account!(id), do: Repo.get!(GmailAccount, id)

  @doc """
  Gets a gmail_account by email and user_id.
  """
  def get_gmail_account_by_email(email, user_id) do
    Repo.get_by(GmailAccount, email: email, user_id: user_id)
  end

  @doc """
  Checks if a user already has a Gmail account with the given email.
  """
  def has_gmail_account?(user_id, email) do
    case get_gmail_account_by_email(email, user_id) do
      nil -> false
      _gmail_account -> true
    end
  end

  @doc """
  Creates a gmail_account.
  """
  def create_gmail_account(attrs \\ %{}) do
    %GmailAccount{}
    |> GmailAccount.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a gmail_account.
  """
  def update_gmail_account(%GmailAccount{} = gmail_account, attrs) do
    gmail_account
    |> GmailAccount.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Updates a gmail_account by email and user_id.
  """
  def update_gmail_account_by_email(email, user_id, attrs) do
    case get_gmail_account_by_email(email, user_id) do
      nil -> {:error, "Gmail account not found"}
      gmail_account -> update_gmail_account(gmail_account, attrs)
    end
  end

  @doc """
  Deletes a gmail_account.
  """
  def delete_gmail_account(%GmailAccount{} = gmail_account) do
    Repo.delete(gmail_account)
  end

  @doc """
  Soft deletes a gmail_account by setting is_active to false.
  """
  def deactivate_gmail_account(%GmailAccount{} = gmail_account) do
    update_gmail_account(gmail_account, %{is_active: false})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking gmail_account changes.
  """
  def change_gmail_account(%GmailAccount{} = gmail_account, attrs \\ %{}) do
    GmailAccount.changeset(gmail_account, attrs)
  end
end
