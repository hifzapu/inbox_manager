defmodule InboxManagerWeb.GmailWebhookController do
  use InboxManagerWeb, :controller

  import Ecto.Query, warn: false
  alias InboxManager.ApiClients.GmailClient
  alias InboxManager.Emails.EmailProcessor
  alias InboxManager.Repo
  alias InboxManager.GmailAccounts
  alias InboxManager.GmailAccounts.GmailAccount
  alias InboxManager.Auth.TokenRefresher
  require Logger

  # Handle Gmail push notifications
  def gmail_notification(conn, %{"message" => message_data}) do
    # Decode the base64 message data
    case Base.decode64(message_data["data"]) do
      {:ok, decoded_data} ->
        case Jason.decode(decoded_data) do
          {:ok, %{"emailAddress" => email, "historyId" => history_id}} ->
            # Process the new email notification
            handle_new_email_notification(email, history_id)

            conn
            |> put_status(:ok)
            |> json(%{status: "processed"})

          {:error, _} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Invalid message format"})
        end

      :error ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid base64 data"})
    end
  end

  def gmail_notification(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing message data"})
  end

  # Handle new email notifications
  defp handle_new_email_notification(email, history_id) do
    # Get all Gmail accounts for this email address (multiple users can have the same email connected)
    case get_all_gmail_accounts_by_email(email) do
      {:ok, gmail_accounts} ->
        # Process the email for all users who have this Gmail account connected
        Enum.each(gmail_accounts, fn gmail_account ->
          # Update the history ID for this specific Gmail account connection
          GmailAccounts.update_gmail_account(gmail_account, %{
            last_known_history_id: Integer.to_string(history_id)
          })

          # Process new emails for this Gmail account connection
          process_new_emails_for_gmail_account(gmail_account, gmail_account.last_known_history_id)
        end)

      {:error, :gmail_account_not_found} ->
        Logger.warning("No Gmail account found for email: #{email}")
    end
  end

  defp get_all_gmail_accounts_by_email(email) do
    # Find all Gmail accounts for this email address (multiple users can have the same email connected)
    gmail_accounts =
      Repo.all(from g in GmailAccount, where: g.email == ^email and g.is_active == true)

    case gmail_accounts do
      [] -> {:error, :gmail_account_not_found}
      accounts -> {:ok, accounts}
    end
  end

  # Keep the old function for backward compatibility but mark it as deprecated
  defp get_gmail_account_by_email(email) do
    # Find the Gmail account by email (since email should be unique across all users)
    case Repo.get_by(GmailAccount, email: email) do
      nil -> {:error, :gmail_account_not_found}
      gmail_account -> {:ok, gmail_account}
    end
  end

  defp process_new_emails_for_gmail_account(gmail_account, history_id) do
    # Get valid access token (refresh if needed)
    case get_valid_token_for_gmail_account(gmail_account) do
      {:ok, valid_token} ->
        # Get the latest messages since the history_id
        case GmailClient.get_messages_since_history(valid_token, history_id) do
          {:ok, message_ids} ->
            Enum.each(message_ids, fn message_id ->
              EmailProcessor.process_new_email(valid_token, message_id, gmail_account)
            end)

          {:error, error} ->
            Logger.error(
              "Failed to get latest messages for Gmail account #{gmail_account.email}: #{error}"
            )
        end

      {:error, error} ->
        Logger.error(
          "Failed to get valid token for Gmail account #{gmail_account.email}: #{error}"
        )
    end
  end

  # Get a valid access token for a Gmail account, refreshing if necessary
  defp get_valid_token_for_gmail_account(gmail_account) do
    # Create a temporary user struct for token refresh
    temp_user = %InboxManager.Users.User{
      token: gmail_account.token,
      refresh_token: gmail_account.refresh_token,
      token_expires_at: gmail_account.token_expires_at,
      email: gmail_account.email
    }

    case TokenRefresher.ensure_valid_token(temp_user) do
      {:ok, updated_temp_user} ->
        # Update the Gmail account with the new token
        GmailAccounts.update_gmail_account(gmail_account, %{
          token: updated_temp_user.token,
          token_expires_at: updated_temp_user.token_expires_at
        })

        {:ok, updated_temp_user.token}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Health check endpoint for webhook verification
  def health(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "healthy"})
  end
end
