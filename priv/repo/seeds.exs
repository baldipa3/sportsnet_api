# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     SportsnetApi.Repo.insert!(%SportsnetApi.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

IO.puts "Removing countries"
SportsnetApi.Repo.delete_all(%SportsnetApi.Country{})

IO.puts "Removing cities"
SportsnetApi.Repo.delete_all(%SportsnetApi.City{})


countries_and_cities = [
  {"Argentina", ["Buenos Aires", "Cordoba", "Mendoza", "Santa Fe"]},
  {"Spain", ["Madrid", "Barcelona", "Sevilla", "Valencia"]},
  {"United Kingdom", ["London", "Liverpool", "Leeds", "Manchester"]},
]

IO.puts "Creating countries and cities"
Enum.each(countries_and_cities, fn {country_name, city_names} ->
  country = SportsnetApi.Repo.insert!(%SportsnetApi.Geography.Country{
    name: country_name
  })

  Enum.each(city_names, fn city_name ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Geography.City{
    name: city_name,
    country_id: country.id
  })
  end)
end)

IO.puts "Creating users"
SportsnetApi.Repo.insert!(%SportsnetApi.Accounts.User{
  name: "John",
  surname: "Doe",
  email: "john.doe@gmail.com",
  password: "123456",
})

SportsnetApi.Repo.insert!(%SportsnetApi.Accounts.User{
  name: "Anna",
  surname: "Doe",
  email: "anna.doe@gmail.com",
  password: "123456",
})
