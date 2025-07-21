defmodule InboxManagerWeb.CategoryLiveTest do
  use InboxManagerWeb.ConnCase
  import Phoenix.LiveViewTest

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

    # Set the session so the LiveView sees the user as logged in
    conn = Plug.Test.init_test_session(conn, current_user: user)

    {:ok, conn: conn, user: user, category: category}
  end

  test "renders categories for a user", %{conn: conn, category: category} do
    {:ok, view, _html} = live(conn, "/categories")
    assert render(view) =~ category.name
  end

  test "opens new category modal", %{conn: conn} do
    {:ok, view, _html} = live(conn, "/categories")

    view
    |> element("a", "New Category")
    |> render_click()

    assert render(view) =~ "New Category"
  end
end
