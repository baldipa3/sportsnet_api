defmodule SportsnetApi.Social.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    field :deleted_at, :utc_datetime
    field :was_edited, :boolean, virtual: true, default: false

    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :sport, SportsnetApi.Sports.Sport
    belongs_to :city, SportsnetApi.Geography.City
    has_many :comments, SportsnetApi.Social.Comment
    has_many :media, SportsnetApi.Social.Media
    has_many :likes, SportsnetApi.Social.Like

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset to handle posts created by users
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :user_id, :sport_id, :city_id, :deleted_at])
    |> validate_required([:caption, :user_id, :sport_id, :city_id])
  end
end
