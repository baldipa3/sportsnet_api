defmodule SportsnetApi.Social.Media do
  use Ecto.Schema
  import Ecto.Changeset

  schema "media" do
    field :url, :string
    field :media_type, :string
    field :position, :integer
    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime)
  end
end
