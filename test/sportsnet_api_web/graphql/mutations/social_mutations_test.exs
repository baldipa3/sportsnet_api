defmodule SportsnetApiWeb.Graphql.Mutations.SocialMutationsTest do
  use SportsnetApiWeb.ConnCase, async: true

  import SportsnetApi.GraphQLHelpers
  import Absinthe.Relay.Node
  import SportsnetApi.Factory
  import SportsnetApi.Accounts

  alias Plug.Upload
  alias SportsnetApi.Repo
  alias SportsnetApi.Social.PostEdit

  setup %{conn: conn} do
    user = insert(:user)
    city = insert(:city)
    sport = insert(:sport)
    token = create_user_api_token(user)
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
      encoded_city_id: encoded_city_id,
      media: [upload_image, upload_video],
      user: user
    }
  end

  describe "createPost mutation" do
    test "creates a post with media files", %{conn: conn, token: token, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id, media: [image, video], user: user} do
      encoded_user_id = to_global_id("User", user.id)

      mutation = """
        mutation CreatePost($caption: String!, $sportId: ID!, $cityId: ID!, $media: [Upload!]) {
          createPost(caption: $caption, sportId: $sportId, cityId: $cityId, media: $media) {
            postEdge {
              node {
                id
                caption
                media {
                  id
                  url
                  mediaType
                  filename
                }
                user {
                  id
                }
              }
            }
          }
        }
      """

      variables = %{
        "caption" => "A new Post with media",
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

      response = mutation_result(conn, "createPost")
      media = get_in(response, ["postEdge", "node", "media"])
      caption = get_in(response, ["postEdge", "node", "caption"])
      user_id = get_in(response, ["postEdge", "node", "user", "id"])

      assert caption == "A new Post with media"
      assert user_id == encoded_user_id

      assert [
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
      ] = media
    end

    test "creates a post without media files", %{conn: conn, token: token, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id, user: user} do
      encoded_user_id = to_global_id("User", user.id)

      mutation = """
        mutation {
          createPost(caption: "A new Post without media", sportId: "#{encoded_sport_id}", cityId: "#{encoded_city_id}") {
            postEdge {
              node {
                id
                caption
                user {
                  id
                }
              }
            }
          }
        }
      """

      conn = post_graphql(conn, token, mutation)
      response = mutation_result(conn, "createPost")
      caption = get_in(response, ["postEdge", "node", "caption"])
      user_id = get_in(response, ["postEdge", "node", "user", "id"])

      assert caption == "A new Post without media"
      assert user_id == encoded_user_id
    end

    test "returns an error with invalid request data", %{conn: conn, token: token} do
      mutation = """
        mutation {
          createPost(caption: "A new Post", sportId: null, cityId: null) {
            postEdge {
              node {
                id
                caption
              }
            }
          }
        }
      """

      conn = post_graphql(conn, token, mutation)
      response = errors_result(conn)

      assert [
          %{"message" => "Argument \"sportId\" has invalid value null."},
          %{"message" => "Argument \"cityId\" has invalid value null."}
        ] = response
    end

    test "returns an error when caption is blank", %{conn: conn, token: token, encoded_city_id: encoded_city_id, encoded_sport_id: encoded_sport_id} do
      mutation = """
        mutation {
          createPost(caption: "", sportId: "#{encoded_sport_id}", cityId: "#{encoded_city_id}") {
            postEdge {
              node {
                id
                caption
              }
            }
          }
        }
      """

      conn = post_graphql(conn, token, mutation)
      response = errors_result(conn)

      assert [%{"message" => "caption can't be blank"}] = response
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
          likePost(id: "#{encoded_post_id}", doesLike: true) {
            post {
              id
              likesCount
              likedByCurrentUser
            }
          }
        }
      """

      conn = post_graphql(conn, token, mutation)
      response = mutation_result(conn, "likePost")
      post = get_in(response, ["post"])

      assert %{
        "likesCount" => likes_count,
        "id" => post_id,
        "likedByCurrentUser" => true
      } = post

      assert likes_count == 1
      assert encoded_post_id == post_id
    end

    test "unlikes a post and return liked post number", %{conn: conn, user: user, post: post, token: token, encoded_post_id: encoded_post_id} do
      insert(:like, user: user, post: post)

      mutation = """
        mutation {
          likePost(id: "#{encoded_post_id}", doesLike: false) {
            post {
              id
              likesCount
              likedByCurrentUser
            }
          }
        }
      """

      conn = post_graphql(conn, token, mutation)
      response = mutation_result(conn, "likePost")
      post = get_in(response, ["post"])

      assert %{
        "likesCount" => likes_count,
        "id" => post_id,
        "likedByCurrentUser" => false
        } = post

      assert likes_count == 0
      assert encoded_post_id == post_id
    end
  end

  describe "deletePost mutation" do
    test "soft delete a post with media files", %{conn: conn, token: token, user: user} do
      post = insert(:post, user: user)
      encoded_post_id = to_global_id("Post", post.id)

      mutation = """
        mutation DeletePost($id: ID!) {
          deletePost(id: $id) {
            id
          }
        }
      """

      variables = %{
        "id" => encoded_post_id
      }

      conn = post_graphql(conn, token, mutation, variables)
      response = mutation_result(conn, "deletePost")
      post_id = get_in(response, ["id"])

      deleted_post = SportsnetApi.Repo.get!(SportsnetApi.Social.Post, post.id)

      assert post_id == encoded_post_id
      assert %{deleted_at: %DateTime{}} = deleted_post
    end
  end

  describe "editPost mutation" do
    test "post owner can edit its own post", %{conn: conn, token: token, user: user} do
      post = insert(:post, user: user)
      encoded_post_id = to_global_id("Post", post.id)

      mutation = """
        mutation editPost($id: ID!, $caption: String!) {
          editPost(id: $id, caption: $caption) {
            id
            caption
            wasEdited
          }
        }
      """

      variables = %{
        "id" => encoded_post_id,
        "caption" => "Edited post"
      }

      conn = post_graphql(conn, token, mutation, variables)
      response = mutation_result(conn, "editPost")

      assert %{
        "id" => ^encoded_post_id,
        "caption" => "Edited post",
        "wasEdited" => true
      } = response

      edit_post = Repo.get_by(PostEdit, post_id: post.id)
      assert edit_post != nil
      assert edit_post.old_caption == post.caption
      assert edit_post.new_caption == "Edited post"
    end

    test "users cannot edit other user post", %{conn: conn, user: user} do
      user_2 = insert(:user)
      user_2_token = create_user_api_token(user_2)
      post = insert(:post, user: user)
      encoded_post_id = to_global_id("Post", post.id)

      mutation = """
        mutation editPost($id: ID!, $caption: String!) {
          editPost(id: $id, caption: $caption) {
            id
            caption
            wasEdited
          }
        }
      """

      variables = %{
        "id" => encoded_post_id,
        "caption" => "Edited post"
      }

      conn = post_graphql(conn, user_2_token, mutation, variables)
      response = errors_result(conn)

      assert [%{"message" => "Unauthorized" }] = response
    end

    test "post cannot be edited after 15 min", %{conn: conn, token: token, user: user} do
      post = insert(:post, user: user, inserted_at: DateTime.add(DateTime.utc_now(), -16 * 60, :second))
      encoded_post_id = to_global_id("Post", post.id)

      mutation = """
        mutation editPost($id: ID!, $caption: String!) {
          editPost(id: $id, caption: $caption) {
            id
            caption
            wasEdited
          }
        }
      """

      variables = %{
        "id" => encoded_post_id,
        "caption" => "Edited post"
      }

      conn = post_graphql(conn, token, mutation, variables)
      response = errors_result(conn)

      assert [%{"message" => "Posts can only be edited within 15 minutes of creation"}] = response
    end
  end
end
