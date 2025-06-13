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
  """

  @spec create_country(map()) :: {:ok, Country} | {:error, Ecto.Changeset.t()}
  def create_country(attrs) do
    %Country{}
    |> Country.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Create a new City to make it avaiable for users
  ### Examples
  """

  @spec create_city(map()) :: {:ok, City} | {:error, Ecto.Changeset.t()}
  def create_city(attrs) do
    %City{}
    |> City.changeset(attrs)
    |> Repo.insert()
  end
end
