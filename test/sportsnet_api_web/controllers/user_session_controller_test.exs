defmodule SportsnetApiWeb.UserSessionControllerTest do
  use SportsnetApiWeb.ConnCase, async: true

  alias SportsnetApi.Accounts

  import SportsnetApi.Factory

  setup %{conn: conn} do
    user = insert(:user, city: build(:city), default_sport: build(:sport))

    %{user: user, conn: conn}
  end

  describe "POST /users/log_in" do
    test "log_in the user and responds with json", %{conn: conn, user: user} do

      params = %{email: user.email, password: "Password123"}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 200)

      assert json["status"] == "success"
      assert is_binary(json["data"]["token"])
      assert json["data"]["onboarding_required"] == false
      assert json["data"]["city_slug"] != nil
      assert json["data"]["default_sport_slug"] != nil
      assert json["data"]["city_id"] != nil
      assert json["data"]["default_sport_id"] != nil
    end

    test "log_in the user requires onboarding without city/sport", %{conn: conn} do
      user = insert(:user)

      params = %{email: user.email, password: "Password123"}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 200)

      assert json["status"] == "success"
      assert is_binary(json["data"]["token"])
      assert json["data"]["onboarding_required"] == true
    end

    test "responds with errors for invalid email", %{conn: conn} do
      params = %{email: "invalid.email@example.com", password: "Password123"}
      conn = post(conn, ~p"/users/log_in", %{"user" => params})
      json = json_response(conn, 401)

      assert json["status"] == "error"
      assert json["errors"] == "invalid email or password"
    end

    test "responds with errors for invalid password", %{conn: conn, user: user} do
      params = %{email: user.email, password: "invalid-password"}
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
