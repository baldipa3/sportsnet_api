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

    test "return paginated active posts by city and sport when authenticated", %{conn: conn, token: token, user: user, city: city, sport: sport} do
      insert_list(3, :post_with_media, %{user: user, city: city, sport: sport})
      insert(:post_with_media, %{user: user, city: city, sport: sport, deleted_at: DateTime.utc_now()})

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
                  postLikesCount
                  likedByCurrentUser
                  comments(first: 10) {
                    edges {
                      node {
                        content
                      }
                    }
                  }
                  media {
                    url
                  }
                  user {
                    id
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

      # Request 4 posts when having 3 active posts and 1 deleted
      variables = %{
        "citySlug" => city.slug,
        "sportSlug" => sport.slug,
        "first" => 4
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})


      assert %{"data" =>  %{"postsByCityAndSport" => %{
        "sport" => sport_response,
        "city" => city_response,
        "posts" => posts_connection,
      }}} = json_response(conn, 200)

      assert to_global_id("Sport", sport.id) == sport_response["id"]
      assert to_global_id("City", city.id) == city_response["id"]

      assert %{
        "edges" => edges,
        "pageInfo" => page_info
      } = posts_connection

      # Match 3 active posts and ignore deleted one
      assert length(edges) == 3

      assert %{
        "hasNextPage" => false,
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
                 "user" => %{"id" => user_id},
                 "caption" => caption,
                 "insertedAt" => inserted_at,
                 "postLikesCount" => likes_count,
                 "likedByCurrentUser" => liked_by_current_user,
                 "comments" => comments,
                 "media" => media
               } = node

        assert is_binary(id)
        assert is_binary(caption)
        assert is_binary(inserted_at)
        assert is_integer(likes_count)
        assert is_boolean(liked_by_current_user)
        assert %{"edges" => []} = comments
        assert is_list(media)
        assert to_global_id("User", user.id) == user_id

        Enum.each(media, fn media_item ->
          assert %{"url" => url} = media_item
          assert is_binary(url)
          assert String.contains?(url, "images/")
        end)
      end)
    end

    test "fetches next post page using cursor", %{conn: conn, token: token, user: user, city: city, sport: sport} do
      insert_list(3, :post_with_media, %{user: user, city: city, sport: sport})

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

    test "can refetch posts feed by node ID", %{conn: conn, token: token, city: city, sport: sport} do
      query1 = """
        query {
          postsByCityAndSport(citySlug: "#{city.slug}", sportSlug: "#{sport.slug}") {
            id
            sport { name }
            city { name }
          }
        }
      """

      conn1 = conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query1})

      %{"data" => %{"postsByCityAndSport" => %{"id" => feed_id}}} = json_response(conn1, 200)

      # Refetch using node(id:)
      query2 = """
        query {
          node(id: "#{feed_id}") {
            ... on SportCityFeed {
              sport { name }
              city { name }
            }
          }
        }
      """

      conn2 = build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query2})

      assert %{"data" => %{"node" => %{
        "sport" => %{"name" => sport_name},
        "city" => %{"name" => city_name}
      }}} = json_response(conn2, 200)

      assert sport_name == sport.name
      assert city_name == city.name
    end
  end

  describe "comments pagination" do
    setup %{conn: conn} do
      user = insert(:user)
      city = insert(:city)
      sport = insert(:sport)
      token = create_user_api_token(user)
      post = insert(:post_with_media, %{user: user, city: city, sport: sport})
      comments = insert_list(5, :comment, %{post: post, user: user})

      %{conn: conn, token: token, post: post, comments: comments}
    end

    test "fetches paginated comments for a post", %{conn: conn, token: token, post: post} do
      post_global_id = to_global_id("Post", post.id)

      query = """
        query($postId: ID!, $first: Int, $after: String) {
          node(id: $postId) {
            ... on Post {
              id
              caption
              comments(first: $first, after: $after) {
                edges {
                  node {
                    id
                    content
                  }
                  cursor
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
        }
      """

      variables = %{
        "postId" => post_global_id,
        "first" => 3
      }

      conn = conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables})

      assert %{
        "data" => %{
          "node" => %{
            "comments" => %{
              "edges" => edges,
              "pageInfo" => %{
                "hasNextPage" => has_next,
                "endCursor" => end_cursor
              }
            }
          }
        }
      } = json_response(conn, 200)

      assert length(edges) == 3
      assert has_next == true
      assert is_binary(end_cursor)
    end

    test "fetches next page of comments using cursor", %{conn: conn, token: token, post: post} do
      post_global_id = to_global_id("Post", post.id)

      query = """
        query($postId: ID!, $first: Int, $after: String) {
          node(id: $postId) {
            ... on Post {
              comments(first: $first, after: $after) {
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
        }
      """

      # First page
      variables1 = %{"postId" => post_global_id, "first" => 3}

      conn1 = conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables1})

      %{"data" => %{"node" => %{"comments" => %{
        "pageInfo" => %{"endCursor" => cursor}
      }}}} = json_response(conn1, 200)

      # Second page
      variables2 = %{"postId" => post_global_id, "first" => 3, "after" => cursor}

      conn2 = build_conn()
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{query: query, variables: variables2})

      assert %{
        "data" => %{
          "node" => %{
            "comments" => %{
              "edges" => edges,
              "pageInfo" => %{"hasNextPage" => false}
            }
          }
        }
      } = json_response(conn2, 200)

      assert length(edges) == 2  # Remaining comments
    end
  end
end
