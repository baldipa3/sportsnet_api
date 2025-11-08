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
      second_sport = insert(:sport, slug: "sport_slug_1")
      second_city = insert(:city, slug: "city_slug_1")
      post = insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: second_city, sport: second_sport})

      query = """
        query postsByCityAndSport($citySlug: String!, $sportSlug: String!) {
          postsByCityAndSport(citySlug: $citySlug, sportSlug: $sportSlug) {
            sport {
              id
              name
              slug
            }
            city {
              id
              name
              slug
            }
            posts {
              id
              caption
              insertedAt
              likesCount
              likedByCurrentUser
              comments {
                content
              }
              media {
                url
              }
            }
          }
        }
      """

      variables = %{
        "citySlug" => city.slug,
        "sportSlug" => sport.slug,
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})

      assert %{"data" =>  %{"postsByCityAndSport" => %{
        "sport" => sport_response,
        "city" => city_response,
        "posts" => posts
      }}} = json_response(conn, 200)

      assert to_global_id("Sport", sport.id) == sport_response["id"]
      assert to_global_id("City", city.id) == city_response["id"]

      assert length(posts) == 1

      assert [%{
        "id" => post_id,
        "caption" => caption,
        "comments" => comments,
        "media" => media,
        "insertedAt" => inserted_at,
        "likesCount" => likes_count,
        "likedByCurrentUser" => liked_by_current_user
        }] = posts

      expected_post_id = to_global_id("Post", post.id)
      assert post_id == expected_post_id

      assert is_binary(caption)
      assert is_list(comments)
      assert is_list(media)
      assert is_binary(inserted_at)
      assert is_integer(likes_count)
      assert is_boolean(liked_by_current_user)

      Enum.each(media, fn media_item ->
        assert %{"url" => url} = media_item
        assert is_binary(url)
        assert String.contains?(url, "images/")
      end)
    end
  end
end
