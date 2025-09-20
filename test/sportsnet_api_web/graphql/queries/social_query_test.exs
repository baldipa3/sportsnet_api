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
      second_sport = insert(:sport)
      second_city = insert(:city)
      post = insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: second_city, sport: second_sport})

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

      assert length(posts) == 1

      assert [%{
        "id" => post_id,
        "caption" => caption,
        "comments" => comments,
        "media" => media
        }] = posts

      expected_post_id = to_global_id("Post", post.id)
      assert post_id == expected_post_id

      assert is_binary(caption)
      assert is_list(comments)
      assert is_list(media)

      Enum.each(media, fn media_item ->
        assert %{"url" => url} = media_item
        assert is_binary(url)
        assert String.contains?(url, "images/")
      end)
    end
  end
end
