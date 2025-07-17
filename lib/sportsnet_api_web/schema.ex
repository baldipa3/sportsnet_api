defmodule SportsnetApiWeb.Schema do
  use Absinthe.Schema

  alias SportsnetApiWeb.Resolvers.SportsResolver
  alias SportsnetApiWeb.Resolvers.SocialResolver

  import_types Absinthe.Plug.Types

  object :sport do
    field :id, :id
    field :name, :string
    field :code, :string
  end

  object :media do
    field :id, :id
    field :url, :string
    field :media_type, :string
    field :filename, :string
    field :position, :integer
  end

  object :post do
    field :id, :id
    field :caption, :string
    field :user_id, :id
    field :sport_id, :id
    field :city_id, :id
    field :media, list_of(:media)
  end

  query do
    @desc "Get all sports"
    field :all_sports, non_null(list_of(non_null(:sport))) do
      resolve(&SportsResolver.all_sports/3)
    end
  end

  mutation do
    @desc "Create a new post with optional media files"
    field :create_post, :post do
      arg :caption, non_null(:string)
      arg :user_id, non_null(:id)
      arg :sport_id, non_null(:id)
      arg :city_id, non_null(:id)
      arg :media, list_of(non_null(:upload))
      resolve(&SocialResolver.create_post/3)
    end
  end
end
