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
SportsnetApi.Repo.delete!(%SportsnetApi.Country{})


IO.puts "Creating countries"
SportsnetApi.Repo.insert!(%SportsnetApi.Accounts.User{
  name: "John",
  surname: "Doe",
  email: "john.doe@gmail.com",
  password: "123456",
})




SportsnetApi.Repo.insert!(%SportsnetApi.Accounts.User{
  name: "John",
  surname: "Doe",
  email: "john.doe@gmail.com",
  password: "123456",
})
