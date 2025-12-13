defmodule SportsnetApiWeb.UserAuthTest do
  use SportsnetApiWeb.ConnCase, async: true

  alias SportsnetApi.Accounts
  alias SportsnetApiWeb.UserAuth
  import SportsnetApi.AccountsFixtures


  setup do
    %{user: user_fixture()}
  end

  describe "login_user/1" do
    test "generates a api_token for the user", %{user: user} do
      assert {:ok, token} = UserAuth.login_user(user)
      assert is_binary(token)
    end
  end

  describe "logout_user/1" do
    test "invalidates the API token", %{conn: conn, user: user} do
      token = Accounts.create_user_api_token(user)

      conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> UserAuth.logout_user()

      refute Accounts.fetch_user_by_api_token(token) == {:ok, user}
    end
  end

  describe "fetch_api_user/2" do
    test "assigns current_user when token is valid", %{conn: conn, user: user} do
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> UserAuth.fetch_api_user([])

      assert conn.assigns.current_user.id == user.id
      refute conn.halted
    end

    test "halts connection when token is missing", %{conn: conn} do
      conn = UserAuth.fetch_api_user(conn, [])

      assert conn.status == 401
      assert conn.halted
      assert conn.resp_body == "No access for you"
    end

    test "halts connection when token is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalidtoken")
        |> UserAuth.fetch_api_user([])

      assert conn.status == 401
      assert conn.halted
      assert conn.resp_body == "No access for you"
    end
  end
end
