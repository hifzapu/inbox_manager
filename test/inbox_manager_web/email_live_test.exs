defmodule InboxManagerWeb.EmailLiveTest do
  use InboxManagerWeb.ConnCase
  import Phoenix.LiveViewTest

  alias InboxManager.Emails
  alias InboxManager.Categories
  alias InboxManager.Users.User

  setup %{conn: conn} do
    # Insert a real user into the test DB
    user =
      InboxManager.Repo.insert!(%User{
        email: "test@example.com",
        first_name: "Test",
        last_name: "User"
      })

    # Insert a category for this user
    category =
      InboxManager.Repo.insert!(%InboxManager.Categories.Category{
        name: "Work",
        description: "Work stuff",
        user_id: user.id
      })

    # Insert an email for this user and category
    email =
      InboxManager.Repo.insert!(%InboxManager.Emails.Email{
        gmail_id: "test-gmail-id-123",
        subject: "Test Subject",
        from: "sender@example.com",
        to: "test@example.com",
        date: "2024-01-01T12:00:00Z",
        body: "Full email body",
        description: "Short summary",
        user_id: user.id,
        category_id: category.id
      })

    # Set the session so the LiveView sees the user as logged in
    conn = Plug.Test.init_test_session(conn, current_user: user)

    {:ok, conn: conn, user: user, category: category, email: email}
  end

  test "renders emails for a category", %{conn: conn, category: category, email: email} do
    {:ok, view, _html} = live(conn, "/categories/#{category.id}")
    assert render(view) =~ email.subject
  end

  test "shows email details modal when email is clicked", %{
    conn: conn,
    category: category,
    email: email
  } do
    {:ok, view, _html} = live(conn, "/categories/#{category.id}")

    view
    |> element("li[phx-value-id=\"#{email.id}\"]")
    |> render_click()

    assert render(view) =~ email.body
    assert render(view) =~ "From: #{email.from}"
  end

  test "can select and delete emails", %{conn: conn, category: category, email: email} do
    {:ok, view, _html} = live(conn, "/categories/#{category.id}")

    view
    |> element("input[type=\"checkbox\"][value=\"#{email.id}\"]")
    |> render_click()

    view
    |> element("button[phx-click=\"delete_selected\"]")
    |> render_click()

    refute render(view) =~ email.subject
  end
end
