defmodule SportsnetApi.Geography.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :name, :string
    has_many :cities, SportsnetApi.Geography.City

    timestamps(type: :utc_datetime)
  end

  @doc """
    Country changeset for creation

    Requires uniq name
  """

  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name])
    |> update_change(:name, &String.trim/1)
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
