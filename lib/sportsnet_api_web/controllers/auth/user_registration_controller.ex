defmodule SportsnetApiWeb.Auth.UserRegistrationController do
  use SportsnetApiWeb, :controller

  alias SportsnetApi.Accounts

  @doc """
    Handles user registration.

    Expected request body:
      {
        "user": {
          "email": "user@example.com",
          "name": "First",
          "surname": "Last",
          "password": "strongpassword123"
        }
      }

    Responses:
      - 201 Created:
        {
          "status": "success",
          "data": {
            "id": 1,
            "name": "First",
            "surname": "Last",
            "email": "user@example.com",
            "token": "..."
          }
        }

      - 400 Bad Request:
        {
          "status": "error",
          "errors": {
            "email": ["can't be blank"],
            "password": ["can't be blank"]
          }
        }
  """
  @spec create(Plug.Conn.t(), map()) :: Plug.Conn.t()
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
