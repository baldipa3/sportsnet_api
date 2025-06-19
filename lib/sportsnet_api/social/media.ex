defmodule SportsnetApi.Social.Media do
  use Ecto.Schema
  # import Ecto.Changeset

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
end
