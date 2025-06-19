defmodule SportsnetApi.Social.Post do
  use Ecto.Schema
  import Ecto.Changeset

  schema "posts" do
    field :caption, :string
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :sport, SportsnetApi.Sports.Sport
    belongs_to :city, SportsnetApi.Geography.City
    has_many :comments, SportsnetApi.Social.Comment
    has_many :media, SportsnetApi.Social.Media

    timestamps(type: :utc_datetime)
  end

  @doc """
  Changeset to handle posts created by users
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:caption, :user_id, :sport_id, :city_id])
    |> validate_required([:caption, :user_id, :sport_id, :city_id])
  end
end
