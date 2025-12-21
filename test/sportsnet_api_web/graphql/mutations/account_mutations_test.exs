defmodule SportsnetApiWeb.Graphql.Mutations.UserProfileMutationsTest do
  use SportsnetApiWeb.ConnCase, async: true

  import Absinthe.Relay.Node
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
          completeUserOnboarding(cityId: $cityId, defaultSportId: $defaultSportId) {
            id
            city {
              id
              slug
            }
            defaultSport {
              id
              slug
            }
          }
        }
      """

      encoded_city_id = to_global_id("City", city.id)
      encoded_sport_id = to_global_id("Sport", sport.id)

      variables = %{
        "cityId" => encoded_city_id,
        "defaultSportId" => encoded_sport_id,
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
          "city" => %{"id" => city_id, "slug" => city_slug},
          "defaultSport" => %{"id" => default_sport_id, "slug" => default_sport_slug}
        }
      }} = json_response(conn, 200)

      assert city_id == encoded_city_id
      assert default_sport_id == encoded_sport_id
      assert city_slug == city.slug
      assert default_sport_slug == sport.slug
    end


    test "returns an error for non existing city", %{conn: conn, token: token, sport: sport} do
      mutation = """
        mutation CompleteUserOnboarding($cityId: ID!, $defaultSportId: ID!) {
          completeUserOnboarding(cityId: $cityId, defaultSportId: $defaultSportId) {
            id
            city {
              id
              slug
            }
            defaultSport {
              id
              slug
            }
          }
        }
      """

      variables = %{
        "cityId" => to_global_id("City", 9999),
        "defaultSportId" => to_global_id("Sport", sport.id),
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

    test "returns an error for non existing sport", %{conn: conn, token: token, city: city} do
      mutation = """
        mutation CompleteUserOnboarding($cityId: ID!, $defaultSportId: ID!) {
          completeUserOnboarding(city_id: $cityId, defaultSportId: $defaultSportId) {
            id
            city {
              id
              slug
            }
            defaultSport {
              id
              slug
            }
          }
        }
      """

      variables = %{
        "cityId" => to_global_id("City", city.id),
        "defaultSportId" => to_global_id("Sport", 9999),
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
