defmodule SportsnetApi.SocialTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.Social
  alias SportsnetApi.Social.{Post, Comment, Like, PostEdit}
  alias Plug.Upload

  import SportsnetApi.Factory

  describe "create_post/1" do
    setup do
      user = insert(:user)
      test_dir = "tmp/test_uploads"
      File.rm_rf(test_dir)
      File.mkdir_p!(test_dir)

      on_exit(fn ->
        "priv/static/images/"
        |> File.ls!()
        |> Enum.filter(&String.contains?(&1, "test"))
        |> Enum.each(fn file ->
          File.rm("priv/static/images/#{file}")
        end)
      end)

      %{user: user}
    end

    test "creates a post with valid attributes", %{user: user} do
      city = insert(:city)
      sport = insert(:sport)

      attrs = %{
        caption: "An user post message",
        user_id: user.id,
        city_id: city.id,
        sport_id: sport.id
      }

      assert {:ok, %Post{} = post} = Social.create_post(attrs)
      assert post.caption == "An user post message"
      assert post.id != nil
      assert post.user_id != nil
      assert post.city_id != nil
      assert post.sport_id != nil
    end

    test "returns an error with invalid attributes" do
      attrs = %{caption: nil, user_id: nil, city_id: nil, sport_id: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Social.create_post(attrs)
      assert "can't be blank" in errors_on(changeset).caption
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).city_id
      assert "can't be blank" in errors_on(changeset).sport_id
    end

    test "creates a post with media", %{user: user} do
      city = insert(:city)
      sport = insert(:sport)
      tmp_image_path = "tmp/test_image.jpg"
      tmp_video_path = "tmp/test_video.mp4"
      File.write!(tmp_image_path, "fake image data")
      File.write!(tmp_video_path, "fake video data")

      attrs = %{
        caption: "An user post message",
        user_id: user.id,
        city_id: city.id,
        sport_id: sport.id
      }

      upload_1 = %Upload{
        filename: "test_image.jpg",
        path: tmp_image_path,
        content_type: "image/jpeg"
      }

      upload_2 = %Upload{
        filename: "test_video.mp4",
        path: tmp_video_path,
        content_type: "video/mp4"
      }

      assert {:ok, %Post{} = post} = Social.create_post(attrs, [upload_1, upload_2])
      assert length(post.media) == 2

      image = Enum.find(post.media, &(&1.media_type == "image"))
      video = Enum.find(post.media, &(&1.media_type == "video"))

      assert post.caption == "An user post message"
      assert image.media_type == "image"
      assert video.media_type == "video"
      assert image.filename == "test_image.jpg"
      assert video.filename == "test_video.mp4"
      assert image.post_id == post.id
      assert video.post_id == post.id
    end

    test "returns an error when creating a post with invalid media", %{user: user} do
      city = insert(:city)
      sport = insert(:sport)
      tmp_invalid_path = "tmp/test_document.pdf"
      File.write!(tmp_invalid_path, "fake pdf data")

      attrs = %{
        caption: "An user post message",
        user_id: user.id,
        city_id: city.id,
        sport_id: sport.id
      }

      upload_invalid = %Upload{
        filename: "test_document.pdf",
        path: tmp_invalid_path,
        content_type: "application/pdf"
      }

      assert {:error, reason} = Social.create_post(attrs, [upload_invalid])
      assert reason == "Unsupported file extension .pdf"
    end
  end

  describe "create_comment/1" do
    test "creates a comment with valid attributes" do
      user = insert(:user)
      post = insert(:post)
      attrs = %{
        content: "A comment to a post",
        user_id: user.id,
        post_id: post.id,
      }

      assert {:ok, %Comment{} = comment} = Social.create_comment(attrs)
      assert comment.content == "A comment to a post"
      assert comment.user_id != nil
      assert comment.post_id != nil
      assert comment.id != nil
    end

    test "returns an error with invalid attributes" do
      attrs = %{content: nil, user_id: nil, post_id: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Social.create_comment(attrs)
      assert "can't be blank" in errors_on(changeset).content
      assert "can't be blank" in errors_on(changeset).user_id
      assert "can't be blank" in errors_on(changeset).post_id
    end
  end

  describe "like_post/1" do
    test "create a like record on a post from user" do
      user = insert(:user)
      post = insert(:post)

      attrs = %{
        user_id: user.id,
        post_id: post.id,
        does_like: true
      }

      assert {:ok, %Like{} = like} = Social.like_post(attrs)
      assert like.post_id == post.id
      assert like.user_id == user.id
    end
  end

  describe "unlike_post/1" do
    test "destroy a like record on a post from user" do
      user = insert(:user)
      post = insert(:post)
      like = insert(:like, user: user, post: post)

      attrs = %{
        user_id: user.id,
        post_id: post.id,
        does_like: false
      }

      assert {:ok, :unliked} = Social.like_post(attrs)
      refute Repo.get(Like, like.id)
    end
  end

  describe "edit_post/4" do
    test "successfully edits a post with valid attributes" do
      user = insert(:user)
      post = insert(:post, user: user, caption: "Original caption")

      assert {:ok, %Post{} = updated_post} =
        Social.edit_post(post.id, "Updated caption", user, "127.0.0.1")

      assert updated_post.caption == "Updated caption"
      assert updated_post.was_edited == true
      assert updated_post.id == post.id

      post_edit = Repo.get_by(PostEdit, post_id: post.id)
      assert post_edit != nil
      assert post_edit.old_caption == "Original caption"
      assert post_edit.new_caption == "Updated caption"
      assert post_edit.user_id == user.id
      assert post_edit.ip_address == "127.0.0.1"
    end

    test "returns error when post does not exist" do
      user = insert(:user)
      non_existent_id = user.id + 1

      assert {:error, "Post not found"} =
        Social.edit_post(non_existent_id, "New caption", user, "127.0.0.1")
    end

    test "returns error when user is not the post owner" do
      owner = insert(:user)
      other_user = insert(:user)
      post = insert(:post, user: owner, caption: "Original caption")

      assert {:error, "Unauthorized"} =
        Social.edit_post(post.id, "New caption", other_user, "127.0.0.1")
    end

    test "returns error when edit window has expired" do
      user = insert(:user)
      past_time = DateTime.add(DateTime.utc_now(), -20, :minute)
      post = insert(:post, user: user, caption: "Original caption", inserted_at: past_time)

      assert {:error, "Posts can only be edited within 15 minutes of creation"} =
        Social.edit_post(post.id, "New caption", user, "127.0.0.1")
    end

    test "returns error when caption has not changed" do
      user = insert(:user)
      post = insert(:post, user: user, caption: "Same caption")

      assert {:error, "New caption must be different from the current caption"} =
        Social.edit_post(post.id, "Same caption", user, "127.0.0.1")
    end

    test "returns error when caption has not changed (ignoring whitespace)" do
      user = insert(:user)
      post = insert(:post, user: user, caption: "Same caption")

      assert {:error, "New caption must be different from the current caption"} =
        Social.edit_post(post.id, "  Same caption  ", user, "127.0.0.1")
    end

    test "allows editing within the 15-minute window" do
      user = insert(:user)
      recent_time = DateTime.add(DateTime.utc_now(), -10, :minute)
      post = insert(:post, user: user, caption: "Original caption", inserted_at: recent_time)

      assert {:ok, %Post{} = updated_post} =
        Social.edit_post(post.id, "Updated caption", user, "127.0.0.1")

      assert updated_post.caption == "Updated caption"
    end

    test "creates multiple PostEdit records for multiple edits" do
      user = insert(:user)
      post = insert(:post, user: user, caption: "Original caption")

      assert {:ok, _} = Social.edit_post(post.id, "First edit", user, "127.0.0.1")

      assert {:ok, _} = Social.edit_post(post.id, "Second edit", user, "192.168.1.1")

      post_edits = Repo.all(from pe in PostEdit, where: pe.post_id == ^post.id)
      assert length(post_edits) == 2

      [first_edit, second_edit] = Enum.sort_by(post_edits, & &1.inserted_at)
      assert first_edit.new_caption == "First edit"
      assert second_edit.new_caption == "Second edit"
      assert second_edit.old_caption == "First edit"
    end
  end

  describe "delete_post/2" do
    test "successfully soft deletes a post by the owner" do
      user = insert(:user)
      post = insert(:post, user: user)

      assert {:ok, %Post{} = deleted_post} = Social.delete_post(post.id, user)
      assert deleted_post.deleted_at != nil
      assert deleted_post.id == post.id

      db_post = Repo.get(Post, post.id)
      assert db_post.deleted_at != nil
    end

    test "returns error when post does not exist" do
      user = insert(:user)
      non_existent_id = user.id + 1

      assert {:error, "Post not found"} = Social.delete_post(non_existent_id, user)
    end

    test "returns error when user is not the post owner" do
      owner = insert(:user)
      other_user = insert(:user)
      post = insert(:post, user: owner)

      assert {:error, "Unauthorized"} = Social.delete_post(post.id, other_user)
    end
  end
end
