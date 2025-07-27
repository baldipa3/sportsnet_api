defmodule SportsnetApi.Sports.Sport do
  use Ecto.Schema

  import Ecto.Changeset

  schema "sports" do
    field :name, :string
    field :slug, :string
    has_many :posts, SportsnetApi.Social.Post
    has_many :user_sports, SportsnetApi.UserSports.UserSport
    has_many :users, through: [:user_sports, :user]

    timestamps(type: :utc_datetime)
  end

  @doc """
  Sport changeset for creation

  Requires uniq name
  """
  def changeset(sport, attrs) do
    sport
    |> cast(attrs, [:name, :slug])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name, :slug])
    |> unique_constraint(:name)
    |> unique_constraint(:slug)
  end
end
