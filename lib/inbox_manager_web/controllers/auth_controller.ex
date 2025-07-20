defmodule InboxManagerWeb.AuthController do
  use InboxManagerWeb, :controller
  alias InboxManager.Users.User
  alias InboxManager.{AccountContext, Repo}
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
          credentials:
            %{token: token, refresh_token: refresh_token, expires_at: expires_at} = credentails,
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
        changeset =
          User.changeset(
            %User{},
            %{
              email: email,
              first_name: first_name,
              last_name: last_name,
              location: location,
              image: image,
              provider: Atom.to_string(provider),
              token: token,
              refresh_token: refresh_token,
              token_expires_at: expires_at
            }
          )

        signin(conn, changeset)
    end
  end

  def signout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "See you soon.")
    |> redirect(to: "/")
  end

  defp signin(conn, changeset) do
    case upsert(changeset) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Welcome back!")
        |> put_session(:current_user, user)
        |> redirect(to: "/categories")

      {:error, _error} ->
        conn
        |> put_flash(:error, "Signin failed!")
        |> redirect(to: "/")
    end
  end

  def logout(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(external: InboxManager.Auth0.logout_redirect_url())
  end

  defp upsert(changeset) do
    email = changeset.changes.email

    case Repo.get_by(User, email: email) do
      nil ->
        {:ok, user} = Repo.insert(changeset)

        GmailClient.setup_push_notifications(user.token, email)

        {:ok, user}

      user ->
        AccountContext.update_user(user, changeset.changes)
    end
  end
end
