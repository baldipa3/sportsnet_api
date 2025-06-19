defmodule SportsnetApi.Geography.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :name, :string
    field :code, :string
    has_many :cities, SportsnetApi.Geography.City

    timestamps(type: :utc_datetime)
  end

  @doc """
    Country changeset for creation

    Requires uniq name
  """

  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name, :code])
    |> update_change(:name, &String.trim/1)
    |> validate_required([:name, :code])
    |> unique_constraint(:name)
    |> unique_constraint(:code)
  end
end
