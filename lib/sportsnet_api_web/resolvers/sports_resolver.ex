defmodule SportsnetApiWeb.Resolvers.SportsResolver do
  alias SportsnetApi.Sports
  alias SportsnetApi.Helpers.GlobalId

  def all_sports(_parent, _args, _resolution) do
    sports = Sports.list_sports()

    sports_with_global_ids = Enum.map(sports, fn sport ->
      %{sport | id: GlobalId.encode("Sport", sport.id)}
    end)

    {:ok, sports_with_global_ids}
  end
end
