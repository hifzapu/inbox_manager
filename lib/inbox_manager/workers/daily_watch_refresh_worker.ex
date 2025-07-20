defmodule InboxManager.Workers.DailyWatchRefreshWorker do
  @moduledoc """
  Worker that refreshes Gmail watch commands daily for all users.
  Gmail watch commands expire after a certain time, so they need to be refreshed regularly.
  """
  use Oban.Worker, queue: :default

  alias InboxManager.ApiClients.GmailClient
  alias InboxManager.AccountContext
  alias InboxManager.Auth.TokenRefresher
  require Logger

  @impl Oban.Worker
  def perform(_job) do
    Logger.info("Starting daily Gmail watch refresh for all users")

    # Get all users that have Gmail integration
    users = AccountContext.list_users()

    results =
      users
      |> Enum.map(fn user -> refresh_watch_for_user(user) end)

    # Log summary
    successful = Enum.count(results, &match?({:ok, _}, &1))
    failed = Enum.count(results, &match?({:error, _}, &1))

    Logger.info("Daily watch refresh completed: #{successful} successful, #{failed} failed")

    :ok
  end

  defp refresh_watch_for_user(user) do
    Logger.info("Refreshing Gmail watch for user: #{user.email}")

    # Ensure we have a valid access token
    case TokenRefresher.ensure_valid_token(user) do
      {:ok, updated_user} ->
        # Stop existing watch (if any)
        GmailClient.stop_push_notifications(updated_user.token, updated_user.email)

        # Wait a moment before setting up new watch
        Process.sleep(1000)

        # Set up new watch
        case GmailClient.setup_push_notifications(updated_user.token, updated_user.email) do
          {:ok, response} ->
            Logger.info("Successfully refreshed watch for #{user.email}: #{inspect(response)}")
            {:ok, response}

          {:error, error} ->
            Logger.error("Failed to refresh watch for #{user.email}: #{inspect(error)}")
            {:error, error}
        end

      {:error, reason} ->
        Logger.error("Failed to get valid token for #{user.email}: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
