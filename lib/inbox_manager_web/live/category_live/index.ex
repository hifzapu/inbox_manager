defmodule InboxManagerWeb.Categories.Index do
  use InboxManagerWeb, :live_view

  alias InboxManager.Categories
  alias InboxManager.Categories.Category

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:categories, Categories.list_categories())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Category")
    |> assign(:category, %Category{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Categories")
    |> assign(:category, nil)
  end
end
