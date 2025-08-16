defmodule SportsnetApi.Geography do
  @moduledoc """
  The Geography context - handles countries, cities, and location-related business logic
  """

  import Ecto.Query, warn: false

  alias SportsnetApi.Repo
  alias SportsnetApi.Geography.{Country, City}

  @doc """
  Create a new Country to make it available for users
  ## Examples

    iex> create_country(%{field: value})
    {:ok, %Contry{}}

    iex> create_country(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """

  @spec create_country(map()) :: {:ok, Country} | {:error, Ecto.Changeset.t()}
  def create_country(attrs) do
    %Country{}
    |> Country.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create a new City to make it avaiable for users
  ## Examples

    iex> create_city(%{field: value})
    {:ok, %City{}}

    iex> create_city(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """

  @spec create_city(map()) :: {:ok, City} | {:error, Ecto.Changeset.t()}
  def create_city(attrs) do
    %City{}
    |> City.changeset(attrs)
    |> Repo.insert()
  end

  def list_countries_with_cities do
    Country
    |> Repo.all(preload: [:cities])
  end

  def list_cities(country_id) do
    City
    |> where(country_id: ^country_id)
    |> Repo.all()
  end
end
