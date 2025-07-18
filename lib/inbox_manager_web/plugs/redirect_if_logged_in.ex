defmodule InboxManagerWeb.Plugs.RedirectIfLoggedIn do
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    if get_session(conn, :current_user) do
      conn
      |> redirect(to: "/categories")
      |> halt()
    else
      conn
    end
  end
end
