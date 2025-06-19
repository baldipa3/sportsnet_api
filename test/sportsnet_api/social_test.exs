defmodule SportsnetApi.SocialTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.Social
  alias SportsnetApi.Social.{Post, Comment}

  import SportsnetApi.Factory

  describe "create_post/1" do
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
