defmodule SportsnetApi.Social.Like do
  use Ecto.Schema
  import Ecto.Changeset

  schema "likes" do
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime)
  end

  def changeset(like, attrs) do
    like
    |> cast(attrs, [:user_id, :post_id])
    |> validate_required([:user_id, :post_id])
    |> unique_constraint([:user_id, :post_id], name: :likes_user_post_unique_index)
  end
end
