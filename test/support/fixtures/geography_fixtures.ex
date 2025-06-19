defmodule SportsnetApi.GeographyFixtures do
  @moduledoc """
  This module define test helpers for creating
  entities via the `SportsnetApi.Geography` context.
  """
  def valid_country_name, do: "Argentina"

  def valid_country_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      name: valid_country_name(),
      code: "AR"
    })
  end

  def country_fixture(attrs \\ %{}) do
    attrs
    |> valid_country_attributes()
    |> SportsnetApi.Geography.create_country()
  end
end
