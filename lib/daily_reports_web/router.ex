defmodule DailyReportsWeb.Router do
  use DailyReportsWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug OpenApiSpex.Plug.PutApiSpec, module: DailyReportsWeb.ApiSpec
  end

  pipeline :api_auth do
    plug :accepts, ["json"]
    plug DailyReportsWeb.Plugs.AuthenticateUser
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # OpenAPI documentation
  scope "/api" do
    pipe_through :api

    get "/openapi", DailyReportsWeb.ApiSpecController, :spec
  end

  # Scalar API documentation UI
  scope "/api" do
    pipe_through :browser

    get "/docs", DailyReportsWeb.ScalarController, :index
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

    # User routes
    scope "/users", Accounts do
      get "/", UserController, :index
      get "/me", UserController, :me
      put "/me", UserController, :update
      post "/", UserController, :create
    end

    # Project routes
    scope "/projects", Projects do
      post "/", ProjectController, :create
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
