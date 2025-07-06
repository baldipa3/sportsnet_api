defmodule SportsnetApi.SocialTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.Social
  alias SportsnetApi.Social.{Post, Comment}

  import SportsnetApi.Factory

  describe "create_post/1" do
    setup do
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

      :ok
    end

    test "creates a post with valid attributes" do
      user = insert(:user)
      city = insert(:city)
      sport = insert(:sport)

      attrs = %{
        caption: "An user post message",
        user_id: user.id,
        city_id: city.id,
        sport_id: sport.id
      }

      assert {:ok, {%Post{} = post, _media}} = Social.create_post(attrs)
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

    test "creates a post with media" do
      user = insert(:user)
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

      upload_1 = %Plug.Upload{
        filename: "test_image.jpg",
        path: tmp_image_path,
        content_type: "image/jpeg"
      }

      upload_2 = %Plug.Upload{
        filename: "test_video.mp4",
        path: tmp_video_path,
        content_type: "video/mp4"
      }

      assert {:ok, {%Post{} = post, media_list}} = Social.create_post(attrs, [upload_1, upload_2])
      assert length(media_list) == 2

      image = Enum.find(media_list, &(&1.media_type == "image"))
      video = Enum.find(media_list, &(&1.media_type == "video"))

      assert post.caption == "An user post message"
      assert image.media_type == "image"
      assert video.media_type == "video"
      assert image.filename == "test_image.jpg"
      assert video.filename == "test_video.mp4"
      assert image.post_id == post.id
      assert video.post_id == post.id
    end

    test "returns an error when creating a post with invalid media" do
      user = insert(:user)
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

      upload_invalid = %Plug.Upload{
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
end
