defmodule DailyReportsWeb.Router do
  use DailyReportsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug DailyReportsWeb.Plugs.AuthenticateUser
  end

  # Public API routes
  scope "/api", DailyReportsWeb do
    pipe_through :api

    # Authentication routes
    scope "/auth", Accounts do
      post "/login", AuthController, :login
      post "/refresh", AuthController, :refresh
      post "/logout", AuthController, :logout
    end
  end

  # Protected API routes
  scope "/api", DailyReportsWeb do
    pipe_through :api_auth

    # User profile routes
    scope "/users", Accounts do
      get "/me", UserController, :me
      put "/me", UserController, :update
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:daily_reports, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: DailyReportsWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
