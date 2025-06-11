defmodule SportsnetApi.Geography.Country do
  use Ecto.Schema
  import Ecto.Changeset

  schema "countries" do
    field :name, :string

    timestamps(type: :utc_datetime)
  end

  @doc """
    Country changeset for creation

    Requires uniq name
  """

  def changeset(country, attrs) do
    country
    |> cast(attrs, [:name])
    |> validate_required(:name)
    |> unique_constraint(:name)
  end
end
