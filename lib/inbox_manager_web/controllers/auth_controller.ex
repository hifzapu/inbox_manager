defmodule InboxManagerWeb.AuthController do
  use InboxManagerWeb, :controller
  alias InboxManager.Users.User
  alias InboxManager.{Repo, GmailAccounts}
  alias InboxManager.ApiClients.GmailClient

  plug Ueberauth
  require Logger

  def callback(%{assigns: assigns} = conn, _params) do
    case assigns do
      %{ueberauth_failure: %{errors: [errors]}} ->
        %{message: message} = errors

        conn
        |> put_flash(:error, message)
        |> redirect(to: "/")

      %{
        ueberauth_auth: %{
          credentials: credentials,
          info: %{
            email: email,
            first_name: first_name,
            last_name: last_name,
            location: location,
            image: image
          },
          provider: provider
        }
      } ->
        # Debug logging to see what credentials we're getting
        Logger.info("Auth callback credentials: #{inspect(credentials)}")
        Logger.info("Auth callback full assigns: #{inspect(assigns)}")

        case credentials do
          %{token: token, refresh_token: refresh_token, expires_at: expires_at} ->
            # Check if there's already a logged-in user
            case get_session(conn, :current_user) do
              nil ->
                # No logged-in user, proceed with normal login flow
                handle_new_user_login(conn, %{
                  email: email,
                  first_name: first_name,
                  last_name: last_name,
                  location: location,
                  image: image,
                  provider: provider,
                  token: token,
                  refresh_token: refresh_token,
                  expires_at: expires_at
                })

              existing_user ->
                # User is already logged in, connect the new Gmail account to existing user
                handle_gmail_account_connection_for_existing_user(conn, existing_user, %{
                  email: email,
                  first_name: first_name,
                  last_name: last_name,
                  image: image,
                  token: token,
                  refresh_token: refresh_token,
                  expires_at: expires_at
                })
            end

          %{token: token, expires_at: expires_at} ->
            # No refresh token received
            Logger.warning("No refresh token received for user #{email}")

            conn
            |> put_flash(
              :error,
              "Authentication failed: No refresh token received. Please try again."
            )
            |> redirect(to: "/")

          _ ->
            Logger.error("Unexpected credentials format: #{inspect(credentials)}")

            conn
            |> put_flash(:error, "Authentication failed: Unexpected response format.")
            |> redirect(to: "/")
        end
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "See you soon.")
    |> redirect(to: "/")
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  # Debug endpoint to test OAuth flow
  def debug_auth(conn, _params) do
    conn
    |> put_session(:debug_mode, true)
    |> redirect(to: "/auth/google")
  end

  # Force re-authorization by clearing session
  def force_reauth(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "Session cleared. Please re-authorize to get refresh token.")
    |> redirect(to: "/auth/google")
  end

  defp ensure_user_exists(changeset) do
    email = changeset.changes.email

    case Repo.get_by(User, email: email) do
      nil ->
        Repo.insert(changeset)

      user ->
        {:ok, user}
    end
  end

  defp handle_gmail_account_connection(user, gmail_account_attrs) do
    # Check if this Gmail account is already connected to this user
    case GmailAccounts.get_gmail_account_by_email(gmail_account_attrs.email, user.id) do
      nil ->
        # New Gmail account connection
        case GmailAccounts.create_gmail_account(gmail_account_attrs) do
          {:ok, gmail_account} ->
            # Set up push notifications for the new account and get history ID
            case GmailClient.setup_push_notifications(gmail_account.token, gmail_account.email) do
              {:ok, %{"historyId" => history_id}} ->
                # Update the Gmail account with the history ID

                GmailAccounts.update_gmail_account(gmail_account, %{
                  last_known_history_id: history_id
                })

                {:ok, gmail_account}

              {:ok, _response} ->
                # No history ID in response, but account was created successfully
                {:ok, gmail_account}

              {:error, error} ->
                Logger.error("Failed to setup push notifications: #{inspect(error)}")
                {:error, error}
            end

          {:error, changeset} ->
            Logger.error("Failed to create Gmail account: #{inspect(changeset.errors)}")
            {:error, changeset}
        end

      existing_gmail_account ->
        # Update existing Gmail account with new tokens
        case GmailAccounts.update_gmail_account(existing_gmail_account, gmail_account_attrs) do
          {:ok, updated_gmail_account} ->
            # Refresh push notifications and get new history ID
            case GmailClient.setup_push_notifications(
                   updated_gmail_account.token,
                   updated_gmail_account.email
                 ) do
              {:ok, %{"historyId" => history_id}} ->
                # Update the Gmail account with the new history ID
                GmailAccounts.update_gmail_account(updated_gmail_account, %{
                  last_known_history_id: history_id
                })

                {:ok, updated_gmail_account}

              {:ok, _response} ->
                # No history ID in response, but account was updated successfully
                {:ok, updated_gmail_account}

              {:error, error} ->
                Logger.error("Failed to setup push notifications: #{inspect(error)}")
                {:error, error}
            end

          {:error, changeset} ->
            Logger.error("Failed to update Gmail account: #{inspect(changeset.errors)}")
            {:error, changeset}
        end
    end
  end

  defp handle_new_user_login(conn, auth_data) do
    # First, ensure we have a user (create if doesn't exist)
    user_changeset =
      User.changeset(
        %User{},
        %{
          email: auth_data.email,
          first_name: auth_data.first_name,
          last_name: auth_data.last_name,
          location: auth_data.location,
          image: auth_data.image,
          token: auth_data.token,
          refresh_token: auth_data.refresh_token,
          token_expires_at: auth_data.expires_at,
          provider: Atom.to_string(auth_data.provider)
        }
      )

    case ensure_user_exists(user_changeset) do
      {:ok, user} ->
        # Now handle the Gmail account connection
        gmail_account_attrs = %{
          email: auth_data.email,
          first_name: auth_data.first_name,
          last_name: auth_data.last_name,
          image: auth_data.image,
          token: auth_data.token,
          refresh_token: auth_data.refresh_token,
          token_expires_at: auth_data.expires_at,
          user_id: user.id
        }

        case handle_gmail_account_connection(user, gmail_account_attrs) do
          {:ok, _gmail_account} ->
            conn
            |> put_flash(:info, "Gmail account connected successfully!")
            |> put_session(:current_user, user)
            |> redirect(to: "/gmail-accounts")

          {:error, _error} ->
            conn
            |> put_flash(:error, "Failed to connect Gmail account!")
            |> redirect(to: "/gmail-accounts")
        end

      {:error, _error} ->
        conn
        |> put_flash(:error, "Signin failed!")
        |> redirect(to: "/")
    end
  end

  defp handle_gmail_account_connection_for_existing_user(conn, existing_user, auth_data) do
    # Connect the new Gmail account to the existing user
    gmail_account_attrs = %{
      email: auth_data.email,
      first_name: auth_data.first_name,
      last_name: auth_data.last_name,
      image: auth_data.image,
      token: auth_data.token,
      refresh_token: auth_data.refresh_token,
      token_expires_at: auth_data.expires_at,
      user_id: existing_user.id
    }

    case handle_gmail_account_connection(existing_user, gmail_account_attrs) do
      {:ok, _gmail_account} ->
        conn
        |> put_flash(:info, "Gmail account connected successfully!")
        |> redirect(to: "/gmail-accounts")

      {:error, _error} ->
        conn
        |> put_flash(:error, "Failed to connect Gmail account!")
        |> redirect(to: "/gmail-accounts")
    end
  end
end
