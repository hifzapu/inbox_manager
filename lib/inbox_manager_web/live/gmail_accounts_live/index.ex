defmodule InboxManagerWeb.GmailAccountsLive.Index do
  use InboxManagerWeb, :live_view

  alias InboxManager.GmailAccounts
  alias InboxManager.GmailAccounts.GmailAccount
  alias InboxManager.ApiClients.GmailClient
  alias InboxManager.Auth.TokenRefresher
  require Logger

  @impl true
  def mount(_params, %{"current_user" => current_user}, socket) do
    gmail_accounts =
      GmailAccounts.list_gmail_accounts(current_user.id)
      |> Enum.reject(fn account -> account.email == current_user.email end)

    {:ok,
     socket
     |> assign(:current_user, current_user)
     |> assign(:gmail_accounts, gmail_accounts)
     |> assign(:page_title, "Gmail Accounts")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Gmail Accounts")
    |> assign(:gmail_account, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    gmail_account = GmailAccounts.get_gmail_account!(id)

    # Stop Gmail watch before deactivating the account
    case stop_gmail_watch(gmail_account) do
      {:ok, _} ->
        Logger.info("Successfully stopped Gmail watch for account: #{gmail_account.email}")

      {:error, error} ->
        Logger.warning(
          "Failed to stop Gmail watch for account #{gmail_account.email}: #{inspect(error)}"
        )
    end

    # Deactivate the account
    {:ok, _} = GmailAccounts.deactivate_gmail_account(gmail_account)

    gmail_accounts = GmailAccounts.list_gmail_accounts(socket.assigns.current_user.id)

    {:noreply,
     socket
     |> assign(:gmail_accounts, gmail_accounts)
     |> put_flash(:info, "Gmail account disconnected successfully")}
  end

  # Stop Gmail push notifications for a Gmail account
  defp stop_gmail_watch(gmail_account) do
    # Get a valid access token for the Gmail account, refreshing if necessary
    case get_valid_token_for_gmail_account(gmail_account) do
      {:ok, valid_token} ->
        GmailClient.stop_push_notifications(valid_token, gmail_account.email)

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

  @impl true
  def render(assigns) do
    ~H"""
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <div class="mb-8">
        <h1 class="text-3xl font-bold text-gray-900">Gmail Accounts</h1>
        <p class="mt-2 text-gray-600">
          Manage your connected Gmail accounts. You can connect multiple Gmail accounts to process emails from all of them.
        </p>
      </div>

      <div class="bg-white shadow rounded-lg">
        <div class="px-4 py-5 sm:p-6">
          <div class="flex justify-between items-center mb-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">
              Connected Accounts
            </h3>
            <.link
              href="/auth/google"
              class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
            >
              <svg class="w-4 h-4 mr-2" viewBox="0 0 24 24">
                <path fill="currentColor" d="M19 13h-6v6h-2v-6H5v-2h6V5h2v6h6v2z" />
              </svg>
              Connect New Account
            </.link>
          </div>

          <div class="space-y-4">
            <%= if Enum.empty?(@gmail_accounts) do %>
              <div class="text-center py-12">
                <svg
                  class="mx-auto h-12 w-12 text-gray-400"
                  fill="none"
                  viewBox="0 0 24 24"
                  stroke="currentColor"
                >
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M3 8l7.89 4.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z"
                  />
                </svg>
                <h3 class="mt-2 text-sm font-medium text-gray-900">No Gmail accounts connected</h3>
                <p class="mt-1 text-sm text-gray-500">
                  Get started by connecting your first Gmail account.
                </p>
                <div class="mt-6">
                  <.link
                    href="/auth/google"
                    class="inline-flex items-center px-4 py-2 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700"
                  >
                    Connect Gmail Account
                  </.link>
                </div>
              </div>
            <% else %>
              <%= for gmail_account <- @gmail_accounts do %>
                <div class="flex items-center justify-between p-4 border border-gray-200 rounded-lg">
                  <div class="flex items-center space-x-4">
                    <%= if gmail_account.image do %>
                      <img class="h-10 w-10 rounded-full" src={gmail_account.image} alt="Profile" />
                    <% else %>
                      <div class="h-10 w-10 rounded-full bg-gray-300 flex items-center justify-center">
                        <span class="text-sm font-medium text-gray-700">
                          {String.first(gmail_account.email) |> String.upcase()}
                        </span>
                      </div>
                    <% end %>
                    <div>
                      <p class="text-sm font-medium text-gray-900">
                        {gmail_account.first_name} {gmail_account.last_name}
                      </p>
                      <p class="text-sm text-gray-500">{gmail_account.email}</p>
                    </div>
                  </div>
                  <div class="flex items-center space-x-2">
                    <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                      Connected
                    </span>
                    <button
                      phx-click="delete"
                      phx-value-id={gmail_account.id}
                      data-confirm="Are you sure you want to disconnect this Gmail account? This will stop processing emails from this account."
                      class="text-red-600 hover:text-red-900 text-sm font-medium"
                    >
                      Disconnect
                    </button>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
