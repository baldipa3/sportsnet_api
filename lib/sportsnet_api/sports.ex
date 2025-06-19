defmodule SportsnetApi.Sports do
  @moduledoc """
  The Sports context - handles all sport-related business logic
  """
  import Ecto.Query, warn: false

  alias SportsnetApi.Repo
  alias SportsnetApi.Sports.Sport

  @doc """
  Creates a new sports to make it available to all users
  ## Examples

    iex> create_sport(%{field: value})
    {:ok, %Sport{}}

    iex> create_sport(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """

  @spec create_sport(map()) :: {:ok, Sport} | {:error, Ecto.Changeset.t()}
  def create_sport(attrs) do
    %Sport{}
    |> Sport.changeset(attrs)
    |> Repo.insert()
  end
end
