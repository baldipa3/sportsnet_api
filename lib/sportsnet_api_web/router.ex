defmodule SportsnetApiWeb.Router do
  use SportsnetApiWeb, :router

  import SportsnetApiWeb.UserAuth

  pipeline :browser do
    # plug :accepts, ["html"]
    # plug :fetch_session
    # plug :fetch_live_flash
    # plug :put_root_layout, html: {SportsnetApiWeb.Layouts, :root}
    # plug :protect_from_forgery
    # plug :put_secure_browser_headers
    # plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :api_protected do
    plug :accepts, ["json"]
    plug :fetch_api_user
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:sportsnet_api, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: SportsnetApiWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", SportsnetApiWeb do
    pipe_through [:api]  # public routes

    post "/users/register", Auth.UserRegistrationController, :create
    # post "/users/log_in", UserSessionController, :create
    # post "/users/confirm", UserConfirmationController, :create
    # post "/users/confirm/:token", UserConfirmationController, :update
    # post "/users/reset_password", UserResetPasswordController, :create
    # put "/users/reset_password/:token", UserResetPasswordController, :update
  end

  scope "/", SportsnetApiWeb do
    pipe_through :api_protected  # authenticated routes

    # delete "/users/log_out", UserSessionController, :delete
    # put "/users/settings", UserSettingsController, :update
    # post "/users/settings/confirm_email/:token", UserSettingsController, :confirm_email
  end
end
