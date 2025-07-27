defmodule SportsnetApiWeb.UserRegistrationControllerTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.AccountsFixtures

  @valid_attrs %{
    "email" => unique_user_email(),
    "name" => "Test",
    "surname" => "User",
    "password" => "strongpassword123"
  }

  @invalid_attrs %{
    "email" => unique_user_email(),
    "name" => "",
    "surname" => "User",
    "password" => "123"
  }

  describe "POST /users/register" do
    test "creates account and responds with json", %{conn: conn} do
      conn = post(conn, ~p"/users/register", %{"user" => valid_user_attributes(@valid_attrs)})
      json = json_response(conn, 201)

      assert json["status"] == "success"
      assert is_binary(json["data"]["token"])
      assert json["data"]["onboarding_required"] == true
      assert json["data"]["email"] == @valid_attrs["email"]
    end

    test "responds with errors for invalid password", %{conn: conn} do
      conn = post(conn, ~p"/users/register", %{"user" => valid_user_attributes(@invalid_attrs)})
      json = json_response(conn, 400)

      assert json["status"] == "error"
      assert json["errors"]["password"] == ["should be at least 6 character(s)"]
    end

    test "responds with errors for required missing attribute", %{conn: conn} do
      conn = post(conn, ~p"/users/register", %{"user" => valid_user_attributes(@invalid_attrs)})
      json = json_response(conn, 400)

      assert json["status"] == "error"
      assert json["errors"]["name"] == ["can't be blank"]
    end
  end
end
