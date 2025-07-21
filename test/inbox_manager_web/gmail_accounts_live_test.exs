defmodule InboxManagerWeb.GmailAccountsLiveTest do
  use InboxManagerWeb.ConnCase
  import Phoenix.LiveViewTest

  alias InboxManager.GmailAccounts
  alias InboxManager.Users.User

  setup %{conn: conn} do
    # Insert a real user into the test DB
    user =
      InboxManager.Repo.insert!(%User{
        email: "test@example.com",
        first_name: "Test",
        last_name: "User"
      })

    # Insert a Gmail account for this user
    account =
      InboxManager.Repo.insert!(%InboxManager.GmailAccounts.GmailAccount{
        email: "other@gmail.com",
        first_name: "Other",
        last_name: "Account",
        user_id: user.id,
        is_active: true
      })

    # Set the session so the LiveView sees the user as logged in
    conn = Plug.Test.init_test_session(conn, current_user: user)

    {:ok, conn: conn, user: user, account: account}
  end

  test "renders connected Gmail accounts", %{conn: conn, account: account} do
    {:ok, view, _html} = live(conn, "/gmail-accounts")
    assert render(view) =~ account.email
  end

  test "can disconnect a Gmail account", %{conn: conn, account: account} do
    {:ok, view, _html} = live(conn, "/gmail-accounts")

    view
    |> element("button[phx-click=\"delete\"][phx-value-id=\"#{account.id}\"]")
    |> render_click()

    refute render(view) =~ account.email
  end
end
