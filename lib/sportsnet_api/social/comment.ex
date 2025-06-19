defmodule SportsnetApi.Social.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset to handle comments related to a post created by users
  """
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:content, :user_id, :post_id])
    |> validate_required([:content, :user_id, :post_id])
  end
end
