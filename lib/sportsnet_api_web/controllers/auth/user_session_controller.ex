defmodule SportsnetApiWeb.UserSessionController do
  use SportsnetApiWeb, :controller

  alias SportsnetApi.Accounts
  alias SportsnetApiWeb.UserAuth

  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def create(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params
    case Accounts.get_user_by_email_and_password(email, password) do
      {:ok, user} ->
        {:ok, token} = UserAuth.log_in_user(user)

        conn
        |> put_status(:ok)
        |> json(%{
          status: "success",
          data: %{
            token: token
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
    |> UserAuth.log_out_user()
    |> put_status(:ok)
    |> json(%{status: "success", message: "logged out"})
  end
end
