defmodule SportsnetApiWeb.UserSessionControllerTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.AccountsFixtures
  alias SportsnetApi.Accounts

  @valid_email unique_user_email()
  @valid_password "strongpassword123"

  setup %{conn: conn} do
    user = user_fixture(%{email: @valid_email, password: @valid_password})

    %{user: user, conn: conn}
  end

  describe "POST /users/log_in" do
    test "log_in the user and responds with json", %{conn: conn} do
      params = %{email: @valid_email, password: @valid_password}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 200)

      assert json["status"] == "success"
      assert is_binary(json["data"]["token"])
    end

    test "responds with errors for invalid email", %{conn: conn} do
      params = %{email: "invalid.email@example.com", password: @valid_password}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 401)

      assert json["status"] == "error"
      assert json["errors"] == "invalid email or password"
    end

    test "responds with errors for invalid password", %{conn: conn} do
      params = %{email: @valid_email, password: "invalid-password"}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 401)

      assert json["status"] == "error"
      assert json["errors"] == "invalid email or password"
    end
  end

  describe "DELETE /users/log_out" do
    test "log_out the user removing the token", %{conn: conn, user: user} do
      token = Accounts.create_user_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> delete(~p"/users/log_out")

      assert conn.status == 200

      json = json_response(conn, 200)
      assert json["status"] == "success"
      assert json["message"] == "logged out"

      assert Accounts.fetch_user_by_api_token(token) == :error
    end
  end
end
