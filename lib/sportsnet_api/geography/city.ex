defmodule SportsnetApi.Geography.City do
  use Ecto.Schema
  import Ecto.Changeset

  schema "cities" do
    field :name, :string
    field :country_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc """
    City changeset for creation

    Requires uniq name and country
  """

  def changeset(city, attrs) do
    city
    |> cast(attrs, [:name, :country_id])
    |> validate_required([:name, :country_id])
    |> unique_constraint([:name, :country_id])
  end
end
