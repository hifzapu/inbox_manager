defmodule InboxManagerWeb.Router do
  use InboxManagerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {InboxManagerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug InboxManagerWeb.Plugs.FetchSessionUser
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Webhook pipeline - no CSRF protection needed for external webhooks
  pipeline :webhook do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers
  end

  scope "/", InboxManagerWeb do
    pipe_through [:browser, InboxManagerWeb.Plugs.RedirectIfLoggedIn]
    live "/", LoginLive.Index
  end

  scope "/", InboxManagerWeb do
    pipe_through [:browser, InboxManagerWeb.Plugs.RequireAuth]

    live "/categories", Categories.Index, :index
    live "/categories/new", Categories.Index, :new
    live "/emails", EmailLive.Index, :index
  end

  scope "/auth", InboxManagerWeb do
    pipe_through :browser
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  # Webhook endpoints for Gmail push notifications
  scope "/webhooks", InboxManagerWeb do
    pipe_through :webhook

    post "/gmail", GmailWebhookController, :gmail_notification
  end

  # Other scopes may use custom stacks.
  # scope "/api", InboxManagerWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:inbox_manager, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: InboxManagerWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
