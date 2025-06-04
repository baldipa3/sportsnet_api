defmodule SportsnetApiWeb.Auth.UserRegistrationController do
  use SportsnetApiWeb, :controller

  alias SportsnetApi.Accounts

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        token = Accounts.create_user_api_token(user)

        conn
        |> put_status(:created)
        |> json(%{
          status: "success",
          data: %{
            id: user.id,
            name: user.name,
            surname: user.surname,
            email: user.email,
            token: token
          }
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          status: "error",
          errors: Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)
        })
    end
  end
end
