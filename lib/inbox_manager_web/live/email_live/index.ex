defmodule InboxManagerWeb.EmailLive.Index do
  use InboxManagerWeb, :live_view

  alias InboxManager.Emails
  alias InboxManager.Categories

  @impl true
  def mount(_params, _session, socket) do
    # Subscribe to email updates
    if connected?(socket) do
      Phoenix.PubSub.subscribe(InboxManager.PubSub, "email:new")
    end

    # Get initial emails
    emails = Emails.list_emails()
    categories = Categories.list_categories()

    socket =
      socket
      |> assign(:emails, emails)
      |> assign(:categories, categories)
      |> assign(:selected_category, nil)
      |> assign(:loading, false)

    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    category_id = params["category_id"]

    socket =
      socket
      |> assign(:selected_category, category_id)
      |> assign(:page_title, "Emails")

    {:noreply, socket}
  end

  @impl true
  def handle_event("filter-by-category", %{"category-id" => category_id}, socket) do
    emails =
      if category_id == "" do
        Emails.list_emails()
      else
        Emails.list_emails_by_category(category_id)
      end

    {:noreply,
     socket
     |> assign(:emails, emails)
     |> assign(:selected_category, category_id)}
  end

  @impl true
  def handle_event("refresh", _params, socket) do
    emails = Emails.list_emails()

    {:noreply,
     socket
     |> assign(:emails, emails)
     |> assign(:loading, false)}
  end

  # Handle real-time email updates
  @impl true
  def handle_info(%{event: "email:new", payload: %{email: email, category: category}}, socket) do
    # Add the new email to the list
    updated_emails = [email | socket.assigns.emails]

    # Show a flash message
    socket =
      socket
      |> assign(:emails, updated_emails)
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

  defp truncate_text(text, max_length \\ 100) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end
end
