defmodule SportsnetApiWeb.UserSessionController do
  use SportsnetApiWeb, :controller

  import Absinthe.Relay.Node
  alias SportsnetApi.Accounts
  alias SportsnetApiWeb.UserAuth

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params
    case Accounts.get_user_by_email_and_password(email, password) do
      {:ok, user} ->
        {:ok, token} = UserAuth.login_user(user)
        onboarding_required = Accounts.onboarding_required?(user)

        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
          data: %{
            id: to_global_id("User", user.id),
            name: user.name,
            surname: user.surname,
            email: user.email,
            token: token,
            city_id: to_global_id("City", user.city_id),
            default_sport_id: to_global_id("Sport", user.default_sport_id),
            onboarding_required: onboarding_required,
            city_slug: user.city && user.city.slug,
            default_sport_slug: user.default_sport && user.default_sport.slug
          }
        })

      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{
          status: "error",
          errors: "invalid email or password"
        })
    end
  end

  @spec delete(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def delete(conn, _params) do
    conn
    |> UserAuth.logout_user()
    |> put_status(:ok)
    |> json(%{status: "success", message: "logged out"})
  end
end
