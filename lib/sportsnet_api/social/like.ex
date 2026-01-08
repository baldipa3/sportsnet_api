defmodule SportsnetApi.Social.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post
    belongs_to :comment, SportsnetApi.Social.Comment

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id, :comment_id])
    |> validate_required([:user_id])
    |> validate_likeable()
    |> unique_constraint([:user_id, :post_id], name: :likes_user_post_unique_index)
    |> unique_constraint([:user_id, :comment_id], name: :likes_user_comment_unique_index)
  end

  defp validate_likeable(changeset) do
    post_id = get_field(changeset, :post_id)
    comment_id = get_field(changeset, :comment_id)

    cond do
      post_id && comment_id ->
        add_error(changeset, :base, "cannot like both a post and a comment")

      post_id || comment_id ->
        changeset

      true ->
        add_error(changeset, :base, "must like either a post or a comment")
    end
  end
end
