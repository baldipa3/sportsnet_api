defmodule SportsnetApiWeb.Resolvers.SocialResolver do
  alias SportsnetApi.Social
  alias SportsnetApi.Helpers.GlobalId

  import SportsnetApi.Helpers.ErrorHelpers

  def create_post(_parent, args, _resolution) do
    files = Map.get(args, :media, [])
    attrs = Map.drop(args, [:media])

    decoded_attrs = %{
      attrs |
      user_id: decode_id_if_present(attrs[:user_id]),
      sport_id: decode_id_if_present(attrs[:sport_id]),
      city_id: decode_id_if_present(attrs[:city_id])
    }

    case Social.create_post(decoded_attrs, files) do
      {:ok, post} ->
          post_with_global_ids = %{
            id: GlobalId.encode("Post", post.id),
            caption: post.caption,
            user_id: GlobalId.encode("User", post.user_id),
            sport_id: GlobalId.encode("Sport", post.sport_id),
            city_id: GlobalId.encode("City", post.city_id),
            media: Enum.map(post.media || [], fn media ->
              %{
                id: GlobalId.encode("Media", media.id),
                url: media.url,
                media_type: media.media_type,
                filename: media.filename,
                position: media.position
              }
            end)
          }
          {:ok, post_with_global_ids}
      {:error, %Ecto.Changeset{} = changeset} ->
        {:error, format_changeset_errors(changeset)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp decode_id_if_present(nil), do: nil
  defp decode_id_if_present(id) when is_binary(id) do
    case GlobalId.decode_id(id) do
      nil -> id
      decoded_id -> decoded_id
    end
  end
  defp decode_id_if_present(id), do: id
end
