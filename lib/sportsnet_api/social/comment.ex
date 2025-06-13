defmodule SportsnetApi.Social.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comments" do
    field :content, :string
    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime)
  end
end
