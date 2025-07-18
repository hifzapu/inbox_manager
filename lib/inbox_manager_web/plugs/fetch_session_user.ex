defmodule InboxManagerWeb.Plugs.FetchSessionUser do
  import Plug.Conn

  alias Plug.Conn
  alias InboxManager.User

  @behaviour Plug

  def init(opts), do: opts

  def call(%Conn{assigns: %{current_user: %User{}}} = conn, _), do: conn

  def call(%Conn{} = conn, _opts) do
    case get_session(conn, :current_user) do
      %User{} = user -> assign(conn, :current_user, user)
      _ -> conn
    end
  end
end
