defmodule SportsnetApi.Factory do
  use ExMachina.Ecto, repo: SportsnetApi.Repo

  def country_factory do
    country_name = Faker.Address.country()
    base_code = country_name |> String.upcase() |> String.slice(0, 2)

    %SportsnetApi.Geography.Country{
      name: sequence(:country_name, &"#{country_name} - #{&1}"),
      code: sequence(:country_code, &"#{base_code}#{&1}")
    }
  end

  def city_factory do
    city = Faker.Address.city()

    %SportsnetApi.Geography.City{
      name: city,
      slug: String.downcase(sequence(:city_slug, &"#{city}-#{&1}")),
      country: build(:country)
    }
  end

  def sport_factory do
    %SportsnetApi.Sports.Sport{
      name: sequence(:sport_name, &"Sport #{&1}"),
      slug: sequence(:sport_name, &"sport_#{&1}")
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

  def post_with_media_factory(attrs \\ %{}) do
    post = build(:post, attrs)
    media_files = insert_list(2, :media, %{post_id: post.id})

    %{post | media: media_files}
  end

  def media_factory do
    %SportsnetApi.Social.Media{
      url: "images/#{System.system_time(:second)}_post_#{sequence(:post_id, & &1)}_#{Faker.File.file_name(:image)}",
      media_type: "image",
      position: sequence(:position, & &1),
      file_size: Enum.random(1000..5000000),
      filename: Faker.File.file_name(:image),
      width: 1080,
      height: 1080,
    }
  end

  def like_factory do
    %SportsnetApi.Social.Like{
      post: build(:post),
      user: build(:user)
    }
  end

  def comment_factory do
    %SportsnetApi.Social.Comment{
      content: Faker.Lorem.paragraph(),
      user: build(:user),
      post: build(:post),
      parent_comment: nil
    }
  end
end
