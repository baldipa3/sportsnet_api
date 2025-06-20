defmodule SportsnetApi.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `SportsnetApi.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "strongpassword123"
  def valid_user_name, do: "John"
  def valid_user_surname, do: "Doe"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      name: valid_user_name(),
      surname: valid_user_surname()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> SportsnetApi.Accounts.register_user()

    user
  end
end
