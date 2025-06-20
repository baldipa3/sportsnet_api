defmodule SportsnetApi.Sports.Sport do
  use Ecto.Schema

  import Ecto.Changeset

  schema "sports" do
    field :name, :string
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
    |> cast(attrs, [:name])
    |> update_change(:name, &String.trim/1)
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
