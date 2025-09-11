defmodule SportsnetApiWeb.Resolvers.GeographyResolver do
  alias SportsnetApi.Geography

  def countries_with_cities(_parent, _args, _resolution) do
    countries = Geography.list_countries_with_cities()

    {:ok, countries}
  end

  def cities_for_country(country, _args, _resolution) do
    cities = Geography.list_cities(country.id)

    {:ok, cities}
  end
end
