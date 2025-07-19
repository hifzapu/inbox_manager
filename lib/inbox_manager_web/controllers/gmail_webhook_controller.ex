defmodule InboxManagerWeb.GmailWebhookController do
  use InboxManagerWeb, :controller

  alias InboxManager.GmailClient
  alias InboxManager.Emails.EmailProcessor
  alias InboxManager.Repo
  alias InboxManager.Users.User
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
    # Get the user's access token for this email address
    case get_user_by_email(email) do
      {:ok, user} ->
        InboxManager.AccountContext.update_user_by_email(email, %{
          last_known_history_id: history_id
        })

        process_new_emails_for_user(user, user.last_known_history_id)

      {:error, :user_not_found} ->
        Logger.warning("No user found for email: #{email}")
    end
  end

  defp get_user_by_email(email) do
    case Repo.get_by(User, email: email) do
      nil -> {:error, :user_not_found}
      user -> {:ok, user}
    end
  end

  defp process_new_emails_for_user(user, history_id) do
    # Get valid access token (refresh if needed)
    case get_valid_token(user) do
      {:ok, valid_token} ->
        # Get the latest messages since the history_id
        case GmailClient.get_messages_since_history(valid_token, history_id) do
          {:ok, message_ids} ->
            Enum.each(message_ids, fn message_id ->
              EmailProcessor.process_new_email(valid_token, message_id, user)
            end)

          {:error, error} ->
            Logger.error("Failed to get latest messages for user #{user.email}: #{error}")
        end

      {:error, error} ->
        Logger.error("Failed to get valid token for user #{user.email}: #{error}")
    end
  end

  # Get a valid access token, refreshing if necessary
  defp get_valid_token(user) do
    case TokenRefresher.ensure_valid_token(user) do
      {:ok, updated_user} -> {:ok, updated_user.token}
      {:error, reason} -> {:error, reason}
    end
  end

  # Health check endpoint for webhook verification
  def health(conn, _params) do
    conn
    |> put_status(:ok)
    |> json(%{status: "healthy"})
  end
end
