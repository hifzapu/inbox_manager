defmodule InboxManager.Workers.DailyWatchRefreshWorker do
  @moduledoc """
  Worker that refreshes Gmail watch commands daily for all Gmail accounts.
  Gmail watch commands expire after a certain time, so they need to be refreshed regularly.
  """
  use Oban.Worker, queue: :default

  alias InboxManager.ApiClients.GmailClient
  alias InboxManager.GmailAccounts
  alias InboxManager.Auth.TokenRefresher
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("Starting daily Gmail watch refresh for all Gmail accounts")

    # Get all active Gmail accounts
    gmail_accounts = GmailAccounts.list_all_active_gmail_accounts()

    results =
      gmail_accounts
      |> Enum.map(fn gmail_account -> refresh_watch_for_gmail_account(gmail_account) end)

    # Log summary
    successful = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    Logger.info("Daily watch refresh completed: #{successful} successful, #{failed} failed")

    :ok
  end

  defp refresh_watch_for_gmail_account(gmail_account) do
    Logger.info("Refreshing Gmail watch for account: #{gmail_account.email}")

    # Ensure we have a valid access token
    case get_valid_token_for_gmail_account(gmail_account) do
      {:ok, valid_token} ->
        # Stop existing watch (if any)
        GmailClient.stop_push_notifications(valid_token, gmail_account.email)

        # Wait a moment before setting up new watch
        Process.sleep(1000)

        # Set up new watch
        case GmailClient.setup_push_notifications(valid_token, gmail_account.email) do
          {:ok, response} ->
            Logger.info(
              "Successfully refreshed watch for #{gmail_account.email}: #{inspect(response)}"
            )

            {:ok, response}

          {:error, error} ->
            Logger.error("Failed to refresh watch for #{gmail_account.email}: #{inspect(error)}")
            {:error, error}
        end

      {:error, reason} ->
        Logger.error("Failed to get valid token for #{gmail_account.email}: #{inspect(reason)}")
        {:error, reason}
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
end
