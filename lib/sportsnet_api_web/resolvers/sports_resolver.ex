defmodule SportsnetApiWeb.Resolvers.SportsResolver do
  alias SportsnetApi.Sports

  def all_sports(_parent, _args, _resolution) do
    {:ok, Sports.list_sports()}
  end
end
