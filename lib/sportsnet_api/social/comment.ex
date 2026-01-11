defmodule SportsnetApi.Social.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post
    belongs_to :parent_comment, SportsnetApi.Social.Comment

    has_many :replies, SportsnetApi.Social.Comment, foreign_key: :parent_comment_id
    has_many :likes, SportsnetApi.Social.Like
    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset to handle comments related to a post created by users
  """
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id, :parent_comment_id])
    |> validate_required([:content, :user_id, :post_id])
  end
end
