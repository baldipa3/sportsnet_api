defmodule SportsnetApiWeb.Graphql.Mutations.UserProfileMutationsTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  describe "completeOnboardingMutation" do
    setup %{conn: conn} do
      user = insert(:user)
      token = create_user_api_token(user)
      city = insert(:city)
      sport = insert(:sport)

      %{conn: conn, token: token, city: city, sport: sport}
    end

    test "set a city and a default sport to an user", %{conn: conn, token: token, city: city, sport: sport} do
      mutation = """
        mutation CompleteUserOnboarding($cityId: ID!, $defaultSportId: ID!) {
          completeUserOnboarding(city_id: $cityId, default_sport_id: $defaultSportId) {
            id
            name
            default_sport_id
            city_id
          }
        }
      """

      variables = %{
        "cityId" => city.id,
        "defaultSportId" => sport.id
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{
          "query" => mutation,
          "variables" => variables
        })

      assert %{"data" => %{
        "completeUserOnboarding" => %{
          "id" => _,
          "city_id" => city_id,
          "default_sport_id" => default_sport_id
        }
      }} = json_response(conn, 200)

      assert city_id == to_string(city.id)
      assert default_sport_id == to_string(sport.id)
    end


    test "returns an error for non existing city", %{conn: conn, token: token, city: city, sport: sport} do
      mutation = """
        mutation CompleteUserOnboarding($cityId: ID!, $defaultSportId: ID!) {
          completeUserOnboarding(city_id: $cityId, default_sport_id: $defaultSportId) {
            id
            name
            default_sport_id
            city_id
          }
        }
      """

      variables = %{
        "cityId" => city.id + 1,
        "defaultSportId" => sport.id
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{
          "query" => mutation,
          "variables" => variables
        })

      assert %{"errors" => [%{"message" => error_message}]} = json_response(conn, 200)

      assert error_message =~ "City does not exist"
    end

    test "returns an error for non existing sport", %{conn: conn, token: token, city: city, sport: sport} do
      mutation = """
        mutation CompleteUserOnboarding($cityId: ID!, $defaultSportId: ID!) {
          completeUserOnboarding(city_id: $cityId, default_sport_id: $defaultSportId) {
            id
            name
            default_sport_id
            city_id
          }
        }
      """

      variables = %{
        "cityId" => city.id,
        "defaultSportId" => sport.id + 1
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{
          "query" => mutation,
          "variables" => variables
        })

      assert %{"errors" => [%{"message" => error_message}]} = json_response(conn, 200)

      assert error_message =~ "Sport does not exist"
    end
  end
end
