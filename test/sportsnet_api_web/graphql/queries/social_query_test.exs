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

    test "return paginated posts by city and sport when authenticated", %{conn: conn, token: token, user: user, city: city, sport: sport} do
      insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: city, sport: sport})

      other_sport = insert(:sport, slug: "sport_slug_1")
      other_city = insert(:city, slug: "city_slug_1")

      insert(:post_with_media, %{user: user, city: other_city, sport: other_sport})

      query = """
        query postsByCityAndSport($citySlug: String!, $sportSlug: String!, $first: Int, $after: String) {
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
            posts(first: $first, after: $after) {
              edges {
                node {
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
              pageInfo {
                hasNextPage
                hasPreviousPage
                startCursor
                endCursor
              }
            }
          }
        }
      """

      variables = %{
        "citySlug" => city.slug,
        "sportSlug" => sport.slug,
        "first" => 2
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})

      assert %{"data" =>  %{"postsByCityAndSport" => %{
        "sport" => sport_response,
        "city" => city_response,
        "posts" => posts_connection
      }}} = json_response(conn, 200)

      assert to_global_id("Sport", sport.id) == sport_response["id"]
      assert to_global_id("City", city.id) == city_response["id"]

      assert %{
        "edges" => edges,
        "pageInfo" => page_info
      } = posts_connection

      assert length(edges) == 2

      assert %{
        "hasNextPage" => true,
        "hasPreviousPage" => false,
        "startCursor" => start_cursor,
        "endCursor" => end_cursor
      } = page_info

      assert is_binary(start_cursor)
      assert is_binary(end_cursor)

      Enum.each(edges, fn edge ->
        assert %{"node" => node} = edge

        assert %{
                 "id" => id,
                 "caption" => caption,
                 "insertedAt" => inserted_at,
                 "likesCount" => likes_count,
                 "likedByCurrentUser" => liked_by_current_user,
                 "comments" => comments,
                 "media" => media
               } = node

        assert is_binary(id)
        assert is_binary(caption)
        assert is_binary(inserted_at)
        assert is_integer(likes_count)
        assert is_boolean(liked_by_current_user)
        assert is_list(comments)
        assert is_list(media)

        Enum.each(media, fn media_item ->
          assert %{"url" => url} = media_item
          assert is_binary(url)
          assert String.contains?(url, "images/")
        end)
      end)
    end

    test "fetches next page using cursor", %{conn: conn, token: token, user: user, city: city, sport: sport} do
      insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: city, sport: sport})

      query = """
        query postsByCityAndSport($citySlug: String!, $sportSlug: String!, $first: Int, $after: String) {
          postsByCityAndSport(citySlug: $citySlug, sportSlug: $sportSlug) {
            posts(first: $first, after: $after) {
              edges {
                node {
                  id
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        }
      """

      variables = %{
        "citySlug" => city.slug,
        "sportSlug" => sport.slug,
        "first" => 2
      }

      conn1 =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})

      assert %{
               "data" => %{
                 "postsByCityAndSport" => %{
                   "posts" => %{
                     "pageInfo" => %{"hasNextPage" => true, "endCursor" => end_cursor}
                   }
                 }
               }
             } = json_response(conn1, 200)

      variables2 = Map.put(variables, "after", end_cursor)

      conn2 =
        build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables2})

      assert %{
               "data" => %{
                 "postsByCityAndSport" => %{
                   "posts" => %{
                     "edges" => edges,
                     "pageInfo" => %{"hasNextPage" => false}
                   }
                 }
               }
             } = json_response(conn2, 200)

      assert length(edges) == 1
    end
  end
end
