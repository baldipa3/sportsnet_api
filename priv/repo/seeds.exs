require Logger
Logger.configure(level: :info)

IO.puts "Removing Comments"
SportsnetApi.Repo.delete_all(SportsnetApi.Social.Comment)

IO.puts "Removing Posts"
SportsnetApi.Repo.delete_all(SportsnetApi.Social.Post)

IO.puts "Removing sports"
SportsnetApi.Repo.delete_all(SportsnetApi.Sports.Sport)

IO.puts "Removing cities"
SportsnetApi.Repo.delete_all(SportsnetApi.Geography.City)

IO.puts "Removing countries"
SportsnetApi.Repo.delete_all(SportsnetApi.Geography.Country)

IO.puts "Removing Users"
SportsnetApi.Repo.delete_all(SportsnetApi.Accounts.User)

countries_and_cities = [
  {"Argentina", ["Buenos Aires", "Cordoba", "Mendoza", "Santa Fe"]},
  {"Spain", ["Madrid", "Barcelona", "Sevilla", "Valencia"]},
  {"United Kingdom", ["London", "Liverpool", "Leeds", "Manchester"]},
]

sport_names = [ "Football", "Tennis", "Basketball", "Baseball", "Hockey", "Swimming", "Athletics"];

IO.puts "-----------------------------"
IO.puts "Creating countries and cities"
cities = Enum.flat_map(countries_and_cities, fn {country_name, city_names} ->
  country = SportsnetApi.Repo.insert!(%SportsnetApi.Geography.Country{
    name: country_name,
    code: country_name |> String.upcase() |> String.slice(0, 2)
  })

  Enum.map(city_names, fn city_name ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Geography.City{
    name: city_name,
    country_id: country.id
  })
  end)
end)

IO.puts "---------------"
IO.puts "Creating sports"
sports = Enum.map(sport_names, fn sport_name ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Sports.Sport{
    name: sport_name
  })
end)

IO.puts "--------------"
IO.puts "Creating users"
{:ok,user_1} = SportsnetApi.Accounts.register_user(%{
  name: Faker.Person.first_name(),
  surname: Faker.Person.last_name(),
  email: "john.doe@gmail.com",
  password: "Password123"
})

{:ok,user_2} = SportsnetApi.Accounts.register_user(%{
  name: Faker.Person.first_name(),
  surname: Faker.Person.last_name(),
  email: "mary.doe@gmail.com",
  password: "Password123"
})

IO.puts "--------------"
IO.puts "Creating posts"
posts = Enum.map(1..100, fn _x ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Social.Post{
    caption: Faker.Lorem.paragraph(),
    user: user_1,
    city: Enum.random(cities),
    sport: Enum.random(sports)
  })
end)

IO.puts "--------------"
IO.puts "Creating comments"
IO.puts "--------------"
Enum.map(posts, fn post ->
  Enum.map(1..10, fn _x ->
    SportsnetApi.Repo.insert!(%SportsnetApi.Social.Comment{
      content: Faker.Lorem.paragraph(),
      post: post,
      user: user_2
    })
  end)
end)
