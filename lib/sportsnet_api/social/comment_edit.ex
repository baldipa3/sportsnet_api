defmodule SportsnetApi.Social.CommentEdit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "comment_edits" do
    field :old_content, :string
    field :new_content, :string
    field :ip_address, :string

    belongs_to :user, SportsnetApi.Accounts.User
    belongs_to :comment, SportsnetApi.Social.Comment

    timestamps(type: :utc_datetime, updated_at: false, deleted_at: false)
  end

  @doc """
  Changeset to handle comments created by users
  """
  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:old_content, :new_content, :user_id, :comment_id, :ip_address])
    |> validate_required([:new_content, :old_content, :ip_address, :user_id, :comment_id])
  end
end
