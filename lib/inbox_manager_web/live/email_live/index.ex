defmodule InboxManagerWeb.EmailLive.Index do
  use InboxManagerWeb, :live_view

  alias InboxManager.Emails
  alias InboxManager.Categories

  @impl true
  def mount(_params, session, socket) do
    # Subscribe to email updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(InboxManager.PubSub, "email:new")
    end

    # Get current user from session
    current_user = session["current_user"]

    # Get initial emails for the current user

    socket =
      socket
      |> assign(:selected_category, nil)
      |> assign(:loading, false)
      |> assign(:user_id, current_user.id)

    {:ok, socket}
  end

  @impl true
  def handle_params(%{"category_id" => category_id}, _url, socket) do
    # Load emails for the specific category
    emails = Emails.list_emails_by_category(category_id)
    category = Categories.get_category!(category_id)

    socket =
      socket
      |> assign(:emails, emails)
      |> assign(:selected_category, category)
      |> assign(:selected_category_id, category_id)
      |> assign(:page_title, "Emails")

    {:noreply, socket}
  end

  @impl true
  def handle_event("navigate", %{"to" => path}, socket) do
    {:noreply, push_navigate(socket, to: path)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    emails = Emails.list_emails_by_category(socket.assigns.selected_category_id)

    {:noreply,
     socket
     |> assign(:emails, emails)
     |> assign(:loading, false)}
  end

  # Handle real-time email updates
  @impl true
  def handle_info(%{event: "email:new", email: email}, socket) do
    # Add the new email to the list
    emails = Emails.list_emails_by_category(socket.assigns.selected_category_id)
    # Show a flash message
    socket =
      socket
      |> assign(:emails, emails)
      |> put_flash(:info, "New email received: #{email.subject}")

    {:noreply, socket}
  end

  def handle_info(_message, socket) do
    {:noreply, socket}
  end

  defp format_date(date_string) do
    case DateTime.from_iso8601(date_string) do
      {:ok, datetime, _} ->
        Calendar.strftime(datetime, "%B %d, %Y at %I:%M %p")

      _ ->
        date_string
    end
  end

  defp truncate_text(text, max_length) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end
end
