defmodule SportsnetApiWeb.Graphql.Queries.SocialQueryTest do
  use SportsnetApiWeb.ConnCase, async: true

  import Absinthe.Relay.Node
  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  describe "postsByCityAndSport query" do
    setup %{conn: conn} do
      user = insert(:user)
      city = insert(:city)
      sport = insert(:sport)
      token = user |> create_user_api_token()

      %{conn: conn, token: token, user: user, city: city, sport: sport}
    end

    test "return posts by city and sport when authenticated", %{conn: conn, token: token, user: user, city: city, sport: sport} do
      insert(:post_with_media, %{user: user, city: city, sport: sport})

      query = """
        query postsByCityAndSport($cityId: ID!, $sportId: ID!) {
          postsByCityAndSport(cityId: $cityId, sportId: $sportId) {
            id
            caption
            comments {
              content
            }
            media {
              url
            }
          }
        }
      """

      encoded_city_id = to_global_id("City", city.id)
      encoded_sport_id = to_global_id("Sport", sport.id)

      variables = %{
        "cityId" => encoded_city_id,
        "sportId" => encoded_sport_id,
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})

      assert %{"data" =>  %{"postsByCityAndSport" => posts}} = json_response(conn, 200)

      IO.inspect(posts, label: "POSTS:")
    end

    # test "returns an empty list when no sports are found", %{conn: conn, token: token} do
    #   query = """
    #   {
    #     allSports {
    #       id
    #       name
    #       slug
    #     }
    #   }
    #   """

    #   conn =
    #     conn
    #     |> put_req_header("authorization", "Bearer #{token}")
    #     |> post("/graphql", %{query: query})

    #   assert %{"data" =>  %{"allSports" => sports}} = json_response(conn, 200)
    #   assert [] = sports
    # end

    # test "returns 401 when no authenticated", %{conn: conn} do
    #   insert_list(3, :sport)

    #   query = """
    #   {
    #     allSports {
    #       id
    #       name
    #       slug
    #     }
    #   }
    #   """
    #   conn = post(conn, "/graphql", %{query: query})

    #   assert response(conn, 401)
    # end
  end
end
