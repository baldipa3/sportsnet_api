defmodule SportsnetApi.Social.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "media" do
    field :url, :string
    field :media_type, :string
    field :position, :integer
    field :file_size, :integer
    field :filename, :string
    field :width, :integer
    field :height, :integer
    field :duration, :integer

    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime)
  end

  def changeset(media, attrs) do
    media
    |> cast(attrs, [:url, :media_type, :position, :file_size, :filename, :width, :height, :duration, :post_id])
    |> validate_required([:url, :media_type, :file_size, :filename, :post_id])
  end
end
