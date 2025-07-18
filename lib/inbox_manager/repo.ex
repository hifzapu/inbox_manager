defmodule InboxManager.Repo do
  use Ecto.Repo,
    otp_app: :inbox_manager,
    adapter: Ecto.Adapters.Postgres
end
