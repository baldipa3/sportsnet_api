defmodule SportsnetApiWeb.UserAuth do
  use SportsnetApiWeb, :verified_routes

  import Plug.Conn

  alias SportsnetApi.Accounts


  @doc """
  Logs the user in for API authentication.

  Generates a session token for the user that can be used for subsequent
  API requests via the Authorization header as "Bearer <token>".

  Returns `{:ok, token}` tuple containing the generated authentication token.
  """

  @spec log_in_user(SportsnetApi.Accounts.User) :: {:ok, binary()}
  def log_in_user(user) do
    token = Accounts.create_user_api_token(user)

    {:ok, token}
  end

  @doc """
  Logs the user out for API authentication.

  Extracts the Bearer token from the Authorization header and invalidates
  it in the database. If no valid Authorization header is present, the
  function does nothing but still returns the connection.

  This effectively "logs out" the user by making their token unusable
  for future API requests.
  """

  @spec log_out_user(Plug.Conn.t()) :: Plug.Conn.t()
  def log_out_user(conn) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization") do
      Accounts.delete_user_api_token(token)
    end

    conn
  end

  @doc """
  Receives the connection and checks if the "authorization" header has been set with "Bearer TOKEN",
  where "TOKEN" is the value returned by `Accounts.create_user_api_token/1`.
  In case the token is not valid or there is no such user, we abort the request.
  """

  @spec fetch_api_user(Plug.Conn.t(), any()) :: Plug.Conn.t()
  def fetch_api_user(conn, _opts) do
    with ["Bearer " <> token] <- get_req_header(conn, "authorization"),
        {:ok, user} <- Accounts.fetch_user_by_api_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> send_resp(:unauthorized, "No access for you")
        |> halt()
    end
  end
end
