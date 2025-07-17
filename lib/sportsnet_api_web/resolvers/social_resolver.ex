defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Social
  import SportsnetApi.Helpers.ErrorHelpers

  def create_post(_parent, args, _resolution) do
    files = Map.get(args, :media, [])
    attrs = Map.drop(args, [:media])

    case Social.create_post(attrs, files) do
      {:ok, post} -> {:ok, post}
      {:error, %Ecto.Changeset{} = changeset} ->{:error, format_changeset_errors(changeset)}
      {:error, reason} -> {:error, reason}
    end
  end
end
