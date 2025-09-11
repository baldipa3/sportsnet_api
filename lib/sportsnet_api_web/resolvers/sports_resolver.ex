defmodule SportsnetApiWeb.Resolvers.SportsResolver do
  alias SportsnetApi.Sports

  def all_sports(_parent, _args, _resolution) do
    sports = Sports.list_sports()

    {:ok, sports}
  end
end
