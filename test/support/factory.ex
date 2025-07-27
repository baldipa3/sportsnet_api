defmodule SportsnetApi.Factory do
  use ExMachina.Ecto, repo: SportsnetApi.Repo

  def country_factory do
    country_name = Faker.Address.country()

    %SportsnetApi.Geography.Country{
      name: country_name,
      code: country_name |> String.upcase() |> String.slice(0, 2)
    }
  end

  def city_factory do
    %SportsnetApi.Geography.City{
      name: Faker.Address.city(),
      country: build(:country)
    }
  end

  def sport_factory do
    %SportsnetApi.Sports.Sport{
      name: sequence(:sport_name, &"Sport #{&1}"),
      code: sequence(:sport_name, &"sport_#{&1}")
    }
  end

  def user_factory do
    %SportsnetApi.Accounts.User{
      name: Faker.Person.first_name(),
      surname: Faker.Person.last_name(),
      email: Faker.Internet.email(),
      hashed_password: Bcrypt.hash_pwd_salt("Password123"),
      city: nil,
      default_sport: nil
    }
  end

  def post_factory do
    %SportsnetApi.Social.Post{
      caption: Faker.Lorem.paragraph(),
      user: build(:user),
      city: build(:city),
      sport: build(:sport)
    }
  end
end
