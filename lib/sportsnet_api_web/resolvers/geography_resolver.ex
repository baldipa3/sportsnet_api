defmodule SportsnetApiWeb.Resolvers.GeographyResolver do
  alias SportsnetApi.Geography
  alias SportsnetApi.Helpers.GlobalId

  def countries_with_cities(_parent, _args, _resolution) do
    countries = Geography.list_countries_with_cities()

    countries_with_global_ids = Enum.map(countries, fn country ->
      %{country | id: GlobalId.encode("Country", country.id)}
    end)

    {:ok, countries_with_global_ids}
  end

  def cities_for_country(country, _args, _resolution) do
    actual_country_id = GlobalId.decode_id(country.id)

    cities = Geography.list_cities(actual_country_id)

    cities_with_global_ids = Enum.map(cities, fn city ->
      %{city | id: GlobalId.encode("City", city.id)}
    end)

    {:ok, cities_with_global_ids}
  end
end
