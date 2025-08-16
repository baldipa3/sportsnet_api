defmodule SportsnetApiWeb.Graphql.Queries.GeographyQueryTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  describe "countriesWithCities query" do
    setup  %{conn: conn } do
      token = insert(:user) |> create_user_api_token()

      %{conn: conn, token: token}
    end

    test "return all countries with its cities when authenticated", %{conn: conn, token: token} do
      country_1 = insert(:country, name: "Argentina", code:  "AR")
      country_2 = insert(:country, name: "United Kingdom", code: "UK")
      country_3 = insert(:country, name: "Spain", code: "ES")

      insert(:city, name: "Buenos Aires", country: country_1)
      insert(:city, name: "London", country: country_2)
      insert(:city, name: "Madrid", country: country_3)

      query = """
        {
          countriesWithCities {
            id
            name
            code
            cities {
              id
              name
            }
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query})

      assert %{"data" =>  %{"countriesWithCities" => countriesWithCities}} = json_response(conn, 200)

      assert [
          %{
            "cities" => [%{"id" => _, "name" => "Buenos Aires"}],
            "code" => "AR",
            "id" => _,
            "name" => "Argentina"
          },
          %{
            "cities" => [%{"id" => _, "name" => "London"}],
            "code" => "UK",
            "id" => _,
            "name" => "United Kingdom",
          },
          %{
            "cities" => [%{"id" => _, "name" => "Madrid"}],
            "code" => "ES",
            "id" => _,
            "name" => "Spain"
          }
      ] = countriesWithCities
    end
  end
end
