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
      |> assign(:selected_emails, MapSet.new())
      |> assign(:select_all, false)

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

  @impl true
  def handle_event("select_email", %{"id" => email_id}, socket) do
    email_id = String.to_integer(email_id)
    selected_emails = socket.assigns.selected_emails

    new_selected_emails =
      if MapSet.member?(selected_emails, email_id) do
        MapSet.delete(selected_emails, email_id)
      else
        MapSet.put(selected_emails, email_id)
      end

    # Update select_all state based on whether all emails are selected
    select_all = MapSet.size(new_selected_emails) == length(socket.assigns.emails)

    {:noreply,
     socket
     |> assign(:selected_emails, new_selected_emails)
     |> assign(:select_all, select_all)}
  end

  @impl true
  def handle_event("select_all", _params, socket) do
    emails = socket.assigns.emails
    selected_emails = socket.assigns.selected_emails
    select_all = socket.assigns.select_all

    new_selected_emails =
      if select_all do
        # Deselect all
        MapSet.new()
      else
        # Select all
        emails
        |> Enum.map(& &1.id)
        |> MapSet.new()
      end

    {:noreply,
     socket
     |> assign(:selected_emails, new_selected_emails)
     |> assign(:select_all, !select_all)}
  end

  @impl true
  def handle_event("delete_selected", _params, socket) do
    selected_emails = socket.assigns.selected_emails

    if MapSet.size(selected_emails) > 0 do
      email_ids = MapSet.to_list(selected_emails)

      case Emails.delete_emails_by_ids(email_ids) do
        {deleted_count, _} ->
          # Refresh the email list
          emails = Emails.list_emails_by_category(socket.assigns.selected_category_id)

          {:noreply,
           socket
           |> assign(:emails, emails)
           |> assign(:selected_emails, MapSet.new())
           |> assign(:select_all, false)
           |> put_flash(:info, "Successfully deleted #{deleted_count} email(s)")}

        _ ->
          {:noreply,
           socket
           |> put_flash(:error, "Failed to delete emails")}
      end
    else
      {:noreply, socket}
    end
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
