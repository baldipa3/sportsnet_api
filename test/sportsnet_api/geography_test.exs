defmodule SportsnetApi.GeographyTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.Geography
  alias SportsnetApi.Geography.{Country, City}

  import SportsnetApi.GeographyFixtures

  describe "create_country/1" do
    test "creates country with valid attributes" do
      attrs = %{name: "Argentina"}

      assert {:ok, %Country{} = country} = Geography.create_country(attrs)
      assert country.name == "Argentina"
      assert country.id != nil
    end

    test "returns an error with invalid attributes" do
      attrs = %{name: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Geography.create_country(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "returns an error with empty attributes" do
      attrs = %{}

      assert {:error, %Ecto.Changeset{} = changeset} = Geography.create_country(attrs)
      refute changeset.valid?
    end

    test "enforce uniq country name" do
      attrs = %{name: "Spain"}

      assert {:ok, _spain} = Geography.create_country(attrs)

      assert {:error, %Ecto.Changeset{} = changeset} = Geography.create_country(attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "trims whitespace from country name" do
      attrs = %{name: "     Argentina    "}

      assert{:ok, country} = Geography.create_country(attrs)
      assert country.name == "Argentina"
    end
  end

  describe "create_city/1" do

    test "creates cities with valid attributes" do
      {:ok, country} = country_fixture()
      attrs = %{name: "Buenos Aires", country_id: country.id}

      assert {:ok, %City{} = city} = Geography.create_city(attrs)
      assert city.name == "Buenos Aires"
      assert city.id != nil
    end

    test "return error with invalid attributes" do
      {:ok, _country} = country_fixture()
      attrs = %{name: nil, country_id: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Geography.create_city(attrs)
      assert "can't be blank" in errors_on(changeset).name
      assert "can't be blank" in errors_on(changeset).country_id
    end

    test "returns error with empty attributes" do
      attrs = %{}

      assert{:error, %Ecto.Changeset{} = changeset} = Geography.create_city(attrs)
      refute changeset.valid?
    end

    test "enforce uniq city name" do
       {:ok, country} = country_fixture()
       attrs = %{name: "Buenos Aires", country_id: country.id}

       assert {:ok, _city} = Geography.create_city(attrs)
       assert {:error, %Ecto.Changeset{} = changeset} = Geography.create_city(attrs)
       assert "has already been taken" in errors_on(changeset).name
    end

    test "trims whitespace from city name" do
      {:ok, country} = country_fixture()
      attrs = %{name: "     Buenos Aires   ", country_id: country.id}

      assert {:ok, %City{} = city} = Geography.create_city(attrs)
      assert city.name == "Buenos Aires"
    end
  end
end
