defmodule SportsnetApi.Geography.City do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cities" do
    field :name, :string

    belongs_to :country, SportsnetApi.Geography.Country

    has_many :posts, SportsnetApi.Social.Post
    has_many :users, SportsnetApi.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc """
    City changeset for creation

    Requires uniq name and country
  """

  def changeset(city, attrs) do
    city
    |> cast(attrs, [:name, :country_id])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name, :country_id])
    |> unique_constraint([:name, :country_id])
    |> foreign_key_constraint(:country_id)
  end
end
