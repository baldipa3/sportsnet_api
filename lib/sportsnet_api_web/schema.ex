defmodule SportsnetApiWeb.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  alias SportsnetApiWeb.Resolvers.NodeResolver
  alias SportsnetApiWeb.Resolvers.SportsResolver
  alias SportsnetApiWeb.Resolvers.SocialResolver
  alias SportsnetApiWeb.Resolvers.GeographyResolver
  alias SportsnetApiWeb.Resolvers.AccountsResolver

  import_types Absinthe.Plug.Types
  import_types Absinthe.Type.Custom

  node interface do
    resolve_type fn
      %SportsnetApi.Geography.Country{}, _ -> :country
      %SportsnetApi.Geography.City{}, _ -> :city
      %SportsnetApi.Sports.Sport{}, _ -> :sport
      %SportsnetApi.Accounts.User{}, _ -> :user
      %SportsnetApi.Social.Media{}, _ -> :media
      %SportsnetApi.Social.Post{}, _ -> :post
      %{id: _, sport: _, city: _}, _ -> :sport_city_feed
      _, _ ->
        nil
    end
  end

  node object :country do
    field :name, non_null(:string)
    field :code, non_null(:string)

    field :cities, non_null(list_of(non_null(:city))) do
      resolve(&GeographyResolver.cities_for_country/3)
    end
  end

  node object :city do
    field :name, non_null(:string)
    field :slug, non_null(:string)

    field :country, :country do
      resolve fn city, _, _ ->
        city = SportsnetApi.Repo.preload(city, :country)
        case city.country do
          %SportsnetApi.Geography.Country{} = country -> {:ok, country}
          _ -> {:ok, nil}
        end
      end
    end
  end

  node object :sport do
    field :name, non_null(:string)
    field :slug, non_null(:string)
  end

  node object :user do
    field :name, non_null(:string)
    field :surname, non_null(:string)
    field :email, non_null(:string)

    field :city, :city do
      resolve fn user, _, _ ->
        case user.city do
          %SportsnetApi.Geography.City{} = city -> {:ok, city}
          _ -> {:ok, nil}
        end
      end
    end

    field :default_sport, :sport do
      resolve fn user, _, _ ->
        case user.default_sport do
          %SportsnetApi.Sports.Sport{} = sport -> {:ok, sport}
          _ -> {:ok, nil}
        end
      end
    end
  end

  node object :media do
    field :url, :string
    field :media_type, :string
    field :filename, :string
    field :position, :integer
  end

  node object :comment do
    field :content, :string
  end

  node object :post do
    field :caption, non_null(:string)
    field :sport_id, :id
    field :city_id, :id
    field :inserted_at, :datetime
    field :media, list_of(:media)
    field :comments, list_of(:comment)
    field :was_edited, :boolean
    field :likes_count, non_null(:integer) do
      resolve fn post, _, _ ->
        {:ok, SportsnetApi.Social.get_like_count(post.id)}
      end
    end

    field :liked_by_current_user, :boolean do
      resolve fn post, _, resolution ->
        case resolution.context do
          %{current_user: %{id: user_id}} ->
            {:ok, SportsnetApi.Social.user_liked_post?(user_id, post.id)}
          _ ->
            {:ok, false}
        end
      end
    end

    field :user, non_null(:user) do
      resolve fn post, _, _ ->
        {:ok, post.user}
      end
    end
  end

  connection node_type: :post

  object :like_post_payload do
    field :post, non_null(:post)
  end

  node object :sport_city_feed do
    field :sport, non_null(:sport)
    field :city, non_null(:city)

    connection field :posts, node_type: :post do
      resolve(&SocialResolver.posts_connection/3)
    end
  end

  object :create_post_payload do
    field :post_edge, non_null(:post_edge)
  end

  query do
    node field do
      resolve(&NodeResolver.resolve_node/2)
    end

    @desc "Get all sports"
    field :all_sports, non_null(list_of(non_null(:sport))) do
      resolve(&SportsResolver.all_sports/3)
    end

    @desc "Get all countries with their cities"
    field :countries_with_cities, non_null(list_of(non_null(:country))) do
      resolve(&GeographyResolver.countries_with_cities/3)
    end

    @desc "Get posts for a given city/sport combination"
    field :posts_by_city_and_sport, non_null(:sport_city_feed) do
      arg :city_slug, :string
      arg :sport_slug, :string

      resolve(&SocialResolver.posts_by_city_and_sport/3)
    end

    @desc "Get current authenticated user"
    field :current_user, non_null(:user) do
      resolve(&AccountsResolver.current_user/3)
    end
  end

  mutation do
    @desc "Create a new post with optional media files"
    field :create_post, :create_post_payload do
      arg :caption, non_null(:string)
      arg :sport_id, non_null(:id)
      arg :city_id, non_null(:id)
      arg :media, list_of(non_null(:upload))

      resolve(&SocialResolver.create_post/3)
    end

    @desc "Updates user city"
    field :complete_user_onboarding, :user do
      arg :city_id, non_null(:id)
      arg :default_sport_id, non_null(:id)

      resolve(&AccountsResolver.complete_user_onboarding/3)
    end

    @desc "Likes a post"
    field :like_post, :like_post_payload do
      arg :id, non_null(:id)
      arg :does_like, non_null(:boolean)

      resolve(&SocialResolver.like_post/3)
    end

    @desc "Soft delete a post"
    field :delete_post, non_null(:post) do
      arg :id, non_null(:id)

      resolve(&SocialResolver.delete_post/3)
    end

    @desc "Edit a post and record an edit_post"
    field :edit_post, non_null(:post) do
      arg :id, non_null(:id)
      arg :caption, non_null(:string)

      resolve(&SocialResolver.edit_post/3)
    end
  end
end
