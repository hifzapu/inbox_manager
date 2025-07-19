defmodule InboxManagerWeb.Categories.FormComponent do
  use InboxManagerWeb, :live_component

  alias InboxManager.Categories

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
      </.header>

      <.simple_form
        :let={f}
        for={@changeset}
        id="category-form"
        phx-target={@myself}
        phx-submit="save"
      >
        <.input field={{f, :name}} name="category[name]" type="text" label="Name" />
        <.input
          field={{f, :description}}
          name="category[description]"
          type="textarea"
          label="Description"
        />

        <:actions>
          <.button phx-disable-with="Saving...">Save Category</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{category: category} = assigns, socket) do
    changeset = Categories.change_category(category)

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:changeset, changeset)}
  end

  @impl true
  def handle_event("save", %{"category" => category_params}, socket) do
    save_category(socket, socket.assigns.action, category_params)
  end

  defp save_category(socket, :new, category_params) do
    category_params = Map.put(category_params, "user_id", socket.assigns.current_user.id)

    case Categories.create_category(category_params) do
      {:ok, _category} ->
        {:noreply,
         socket
         |> put_flash(:info, "Category created successfully")
         |> push_navigate(to: socket.assigns.navigate)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end
end
