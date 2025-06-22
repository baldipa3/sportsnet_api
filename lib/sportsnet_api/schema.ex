defmodule SportsnetApi.Schema do
  use Absinthe.Schema

  alias SportsnetApi.Resolvers.SportsResolver

  object :sport do
    field :id, :id
    field :name, :string
    field :code, :string
  end

  query do
    @desc "Get all sports"
    field :all_sports, non_null(list_of(non_null(:sport))) do
      resolve(&SportsResolver.all_sports/3)
    end
  end
end
