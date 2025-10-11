defmodule SportsnetApiWeb.Graphql.Mutations.SocialMutationsTest do
  use SportsnetApiWeb.ConnCase, async: true

  import Absinthe.Relay.Node
  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  alias Plug.Upload

  describe "createPost mutation" do
    setup %{conn: conn} do
      user = insert(:user)
      city = insert(:city)
      sport = insert(:sport)
      token = create_user_api_token(user)
      encoded_user_id = to_global_id("User", user.id)
      encoded_city_id = to_global_id("City", city.id)
      encoded_sport_id = to_global_id("Sport", sport.id)

      image_path = "tmp/test_image.jpg"
      video_path = "tmp/test_video.mp4"
      File.write!(image_path, "fake image data")
      File.write!(video_path, "fake video data")

      upload_image = %Upload{
        filename: "test_image.jpg",
        path: image_path,
        content_type: "image/jpeg"
      }

      upload_video = %Upload{
        filename: "test_video.mp4",
        path: video_path,
        content_type: "video/mp4"
      }

      on_exit(fn ->
        Path.wildcard("priv/static/images/*_test_image.jpg") |> Enum.each(&File.rm/1)
        Path.wildcard("priv/static/images/*_test_video.mp4") |> Enum.each(&File.rm/1)
      end)

      %{
        conn: conn,
        token: token,
        encoded_sport_id: encoded_sport_id,
        encoded_user_id: encoded_user_id,
        encoded_city_id: encoded_city_id,
        media: [upload_image, upload_video]
      }
    end

    test "creates a post with media files", %{conn: conn, token: token, encoded_user_id: encoded_user_id, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id, media: [image, video]} do
      mutation = """
        mutation CreatePost($caption: String!, $userId: ID!, $sportId: ID!, $cityId: ID!, $media: [Upload!]) {
          createPost(
            caption: $caption,
            userId: $userId,
            sportId: $sportId,
            cityId: $cityId,
            media: $media
          ) {
            id
            caption
            media {
              id
              url
              mediaType
              filename
            }
          }
        }
      """
      variables = %{
        "caption" => "A new Post with media",
        "userId" => encoded_user_id,
        "sportId" => encoded_sport_id,
        "cityId" => encoded_city_id,
        "media" => ["0", "1"]
      }

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> put_req_header("content-type", "multipart/form-data")
        |> post("/graphql", %{
          "query" => mutation,
          "variables" => Jason.encode!(variables),
          "0" => image,
          "1" => video
        })

      assert %{
        "data" => %{
          "createPost" => %{
            "id" => _id,
            "caption" => "A new Post with media",
            "media" => [
              %{
                "filename" => "test_video.mp4",
                "id" => _,
                "mediaType" => "video",
                "url" => _
              },
              %{
                "filename" => "test_image.jpg",
                "id" => _,
                "mediaType" => "image",
                "url" => _
              }
            ]
          }
        }
      } = json_response(conn, 200)
    end

    test "creates a post without media files", %{conn: conn, token: token, encoded_user_id: encoded_user_id, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id} do
      mutation = """
        mutation {
          createPost(
            caption: "A new Post without media",
            userId: "#{encoded_user_id}",
            sportId: "#{encoded_sport_id}",
            cityId: "#{encoded_city_id}"
          ) {
            id
            caption
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{"query" => mutation})

      assert %{
        "data" => %{
          "createPost" => %{
            "id" => _id,
            "caption" => "A new Post without media"
          }
        }
      } = json_response(conn, 200)
    end

    test "returns an error with invalid request data", %{conn: conn, token: token} do
      mutation = """
        mutation {
          createPost(
            caption: "A new Post",
            userId: asdf,
            sportId: null,
            cityId: null
          ) {
            id
            caption
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{"query" => mutation})

      assert %{
        "errors" => [
          %{"message" => "Argument \"userId\" has invalid value asdf."},
          %{"message" => "Argument \"sportId\" has invalid value null."},
          %{"message" => "Argument \"cityId\" has invalid value null."}
        ]
      } = json_response(conn, 200)
    end

    test "returns an error when caption is blank", %{conn: conn, token: token, encoded_user_id: encoded_user_id, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id} do
      mutation = """
        mutation {
          createPost(
            caption: "",
            userId: "#{encoded_user_id}",
            sportId: "#{encoded_sport_id}",
            cityId: "#{encoded_city_id}"
          ) {
            id
            caption
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{"query" => mutation})

      assert %{
        "errors" => [
          %{"message" => "caption can't be blank"},
        ]
      } = json_response(conn, 200)
    end
  end

  describe "post likes mutations" do
    setup %{conn: conn} do
      user = insert(:user)
      post = insert(:post)
      token = create_user_api_token(user)
      encoded_post_id = to_global_id("Post", post.id)

      %{conn: conn, post: post, token: token, user: user, encoded_post_id: encoded_post_id}
    end

    test "likes a post and return liked post number", %{conn: conn, token: token, encoded_post_id: encoded_post_id} do
      mutation = """
        mutation {
          likePost(
            postId: "#{encoded_post_id}"
          ) {
            postId
            likesCount
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{"query" => mutation})

        assert %{
          "data" => %{"likePost" => %{
            "likesCount" => likes_count,
            "postId" => post_id
          }}} = json_response(conn, 200)

        assert likes_count == 1
        assert encoded_post_id == post_id
    end

    test "unlikes a post and return liked post number", %{conn: conn, user: user, post: post, token: token, encoded_post_id: encoded_post_id} do
      insert(:like, user: user, post: post)

      mutation = """
        mutation {
          unlikePost(
            postId: "#{encoded_post_id}"
          ) {
            postId
            likesCount
          }
        }
      """

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> post("/graphql", %{"query" => mutation})

        assert %{
          "data" => %{"unlikePost" => %{
            "likesCount" => likes_count,
            "postId" => post_id
          }}} = json_response(conn, 200)

        assert likes_count == 0
        assert encoded_post_id == post_id
    end
  end
end
