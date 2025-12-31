defmodule SportsnetApi.Social.PostEdit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "post_edits" do
    field :old_caption, :string
    field :new_caption, :string
    field :ip_address, :string

    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :post, SportsnetApi.Social.Post

    timestamps(type: :utc_datetime, updated_at: false, deleted_at: false)
  end

  @doc """
  Changeset to handle posts created by users
  """
  def changeset(post, attrs) do
    post
    |> cast(attrs, [:old_caption, :new_caption, :user_id, :post_id, :ip_address])
    |> validate_required([:new_caption, :old_caption, :ip_address, :user_id, :post_id])
  end
end
