defmodule SportsnetApi.SportsTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.Sports
  alias SportsnetApi.Sports.Sport

  describe "create_sport/1" do
    test "create a sport with valid attributes" do
      attrs = %{name: "Football"}

      assert {:ok, %Sport{} = sport} = Sports.create_sport(attrs)
      assert sport.name == "Football"
      assert sport.id != nil
    end

    test "returns errors with invalid attributes" do
      attrs = %{name: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Sports.create_sport(attrs)
      assert "can't be blank" in errors_on(changeset).name
    end

    test "return errors with empty attributes" do
      attrs = %{}

      assert {:error, %Ecto.Changeset{} = changeset} = Sports.create_sport(attrs)
      refute changeset.valid?
    end

    test "endorce uniq sport name" do
      attrs = %{name: "Football"}

      assert {:ok, %Sport{}} = Sports.create_sport(attrs)
      assert {:error, %Ecto.Changeset{} = changeset} = Sports.create_sport(attrs)
      assert "has already been taken" in errors_on(changeset).name
    end

    test "trims whitespace from sport name" do
      attrs = %{name: "     Tennis   "}

      assert {:ok, %Sport{} = sport} = Sports.create_sport(attrs)
      assert sport.name == "Tennis"
    end
  end
end
