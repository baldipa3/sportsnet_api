defmodule SportsnetApiWeb.Graphql.Queries.AccountQueryTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  describe "currentUser query" do
    setup %{conn: conn} do
      token = insert(:user, city: build(:city), default_sport: build(:sport)) |> create_user_api_token()

      %{conn: conn, token: token}
    end

    test "return current authenticated user", %{conn: conn, token: token} do
      query = """
      {
        currentUser {
          id
          name
          surname
          email
          city {
            id
            name
            slug
            country {
              id
              name
              code
            }
          }
          defaultSport {
            id
            name
            slug
          }
        }
      }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query})

      assert %{"data" =>  %{"currentUser" => user}} = json_response(conn, 200)
      assert %{
        "id" => _id,
        "name" => _name,
        "surname" => _surname,
        "email" => _email,
        "city" => %{
          "id" => _city_id,
          "name" => _city_name,
          "slug" => _city_slug,
          "country" => %{
            "id" => _country_id,
            "name" => _country_name,
            "code" => _country_code
          }
        },
        "defaultSport" => %{
          "id" => _sport_id,
          "name" => _sport_name,
          "slug" => _sport_slug
        }
      } = user
    end
  end
end
