require Logger
Logger.configure(level: :info)

Code.require_file("web_media_seeder.ex", __DIR__)

IO.puts "Removing Media"
SportsnetApi.Repo.delete_all(SportsnetApi.Social.Media)

IO.puts "Removing Comments"
SportsnetApi.Repo.delete_all(SportsnetApi.Social.Comment)

IO.puts "Removing Posts"
SportsnetApi.Repo.delete_all(SportsnetApi.Social.Post)

IO.puts "Removing Users"
SportsnetApi.Repo.delete_all(SportsnetApi.Accounts.User)

IO.puts "Removing sports"
SportsnetApi.Repo.delete_all(SportsnetApi.Sports.Sport)

IO.puts "Removing cities"
SportsnetApi.Repo.delete_all(SportsnetApi.Geography.City)

IO.puts "Removing countries"
SportsnetApi.Repo.delete_all(SportsnetApi.Geography.Country)


countries_and_cities = [
  {"Argentina", [
    {"Buenos Aires", "buenos_aires"},
    {"Cordoba", "cordoba"},
    {"Mendoza", "mendoza"},
    {"Santa Fe", "santa_fe"}
  ]},
  {"Spain", [
    {"Madrid", "madrid"},
    {"Barcelona", "barcelona"},
    {"Sevilla", "sevilla"},
    {"Valencia", "valencia"}
  ]},
  {"United Kingdom", [
    {"London", "london"},
    {"Liverpool", "liverpool"},
    {"Leeds", "leeds"},
    {"Manchester", "manchester"}
  ]},
  {"France", [
    {"Paris", "paris"},
    {"Lyon", "lyon"},
    {"Marseille", "marseille"},
    {"Toulouse", "toulouse"}
  ]},
  {"Italy", [
    {"Rome", "rome"},
    {"Milan", "milan"},
    {"Naples", "naples"},
    {"Florence", "florence"}
  ]},
  {"Germany", [
    {"Berlin", "berlin"},
    {"Munich", "munich"},
    {"Frankfurt", "frankfurt"},
    {"Hamburg", "hamburg"}
  ]},
  {"Canada", [
    {"Toronto", "toronto"},
    {"Vancouver", "vancouver"},
    {"Montreal", "montreal"},
    {"Calgary", "calgary"}
  ]},
  {"Australia", [
    {"Sydney", "sydney"},
    {"Melbourne", "melbourne"},
    {"Brisbane", "brisbane"},
    {"Perth", "perth"}
  ]}
]

sports_list = [
  {"Football", "football"},
  {"Tennis", "tennis"},
  {"Basketball", "basketball"},
  {"Baseball", "baseball"},
  {"Hockey", "hockey"},
  {"Swimming", "swimming"},
  {"Athletics", "athletics"}
];

IO.puts "-----------------------------"
IO.puts "Creating countries and cities"
cities = Enum.flat_map(countries_and_cities, fn {country_name, city_names} ->
  country = SportsnetApi.Repo.insert!(%SportsnetApi.Geography.Country{
    name: country_name,
    code: country_name |> String.upcase() |> String.slice(0, 2)
  })

  Enum.map(city_names, fn city_name ->
    {name, slug} = city_name
    SportsnetApi.Repo.insert!(%SportsnetApi.Geography.City{
      name: name,
      slug: slug,
      country_id: country.id
    })
  end)
end)

IO.puts "---------------"
IO.puts "Creating sports"
sports = Enum.map(sports_list, fn {name, slug} ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Sports.Sport{
    name: name,
    slug: slug
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

users =
  1..10
  |> Enum.map(fn i ->
    {:ok, user} = SportsnetApi.Accounts.register_user(%{
      name: Faker.Person.first_name(),
      surname: Faker.Person.last_name(),
      email: "user#{i}@gmail.com",
      password: "Password123"
    })
    user
  end)

IO.puts "--------------"
IO.puts "Creating posts with real sports media"
IO.puts "--------------"

posts = Enum.map(1..50, fn x ->
  sport = Enum.random(sports)
  city = Enum.random(cities)

  IO.write("Creating post #{x} (#{sport.name} in #{city.name})...")

  post = SportsnetApi.Repo.insert!(%SportsnetApi.Social.Post{
    caption: WebMediaSeeder.get_sport_caption(sport.name, city.name),
    user: user_1,
    city: city,
    sport: sport
  })

  media_records = WebMediaSeeder.create_media_records_for_post(post, sport.slug)

  IO.puts(" ✓ (#{length(media_records)} media files)")
  post
end)

IO.write("Creating extra post")
sport = SportsnetApi.Repo.get_by(SportsnetApi.Sports.Sport, slug: "football")
city = SportsnetApi.Repo.get_by(SportsnetApi.Geography.City, slug: "buenos_aires")
post = SportsnetApi.Repo.insert!(%SportsnetApi.Social.Post{
  caption: "Football post for testing",
  user: user_1,
  city: city,
  sport: sport
})
WebMediaSeeder.create_media_records_for_post(post, "football")

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

IO.puts "--------------"
IO.puts "Creating likes"
IO.puts "--------------"
Enum.map(posts, fn post ->
  Enum.map(users, fn user ->
    SportsnetApi.Repo.insert!(%SportsnetApi.Social.Like{
      post: post,
      user: user
    })
  end)
end)

Enum.map(users, fn user ->
  SportsnetApi.Repo.insert!(%SportsnetApi.Social.Like{
    post: post,
    user: user
  })
end)

IO.puts "✅ Seed completed successfully!"
