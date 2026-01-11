defmodule SportsnetApi.Social do
  @moduledoc """
  The Social context - handles all social-related business logic
  """

  import Ecto.Query, warn: false

  alias SportsnetApi.Repo
  alias SportsnetApi.Social.{Post, Comment, Media, Like, PostEdit}

  # ==========================================================================
  # Posts
  # ==========================================================================

  @doc """
  Creates a new post by the user, optionally with media files.
  """
  @spec create_post(map(), list()) ::
          {:ok, %Post{}}
          | {:error, Ecto.Changeset.t()}
          | {:error, String.t()}
  def create_post(attrs, files \\ []) do
    Repo.transaction(fn ->
      with {:ok, post} <- insert_post(attrs),
           {:ok, media_records} <- create_media_post(post, files) do
        %{post | media: media_records}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def get_post(post_id) do
    case Repo.get(Post, post_id) do
      nil -> {:error, "Post not found"}
      post -> {:ok, Repo.preload(post, [:user, :media, :comments, :sport, :city])}
    end
  end

  def edit_post(post_id, new_caption, current_user, ip_address) do
    with {:ok, post} <- get_post(post_id),
         :ok <- verify_ownership(post.user_id, current_user.id),
         :ok <- verify_edit_window(post),
         :ok <- verify_caption_changed(post, new_caption),
         {:ok, updated_post} <- perform_edit(post, new_caption, current_user, ip_address) do
      {:ok, updated_post}
    end
  end

  def delete_post(post_id, current_user) do
    with {:ok, post} <- get_post(post_id),
         :ok <- verify_ownership(post.user_id, current_user.id) do
      post
      |> Post.changeset(%{deleted_at: DateTime.utc_now()})
      |> Repo.update()
    end
  end

  # ==========================================================================
  # Comments
  # ==========================================================================

  def create_comment(attrs) do
    Repo.transaction(fn ->
      with {:ok, comment} <- insert_comment(attrs) do
        comment
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def get_comment(comment_id) do
    case Repo.get(Comment, comment_id) do
      nil -> {:error, "Comment not found"}
      comment -> {:ok, Repo.preload(comment, [:user])}
    end
  end

  def list_comments_for_post(post_id) do
    Comment
    |> where([c], c.post_id == ^post_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  def get_replies_count(comment_id) do
    query =
      from c in Comment,
      where: c.parent_comment_id == ^comment_id,
      select: count(c.id)

    Repo.one(query)
  end

  # ==========================================================================
  # Likes
  # ==========================================================================

  @doc """
  Like or unlike a post
  """
  def like_post(%{does_like: true, user_id: user_id, post_id: post_id}) do
    %Like{}
    |> Like.changeset(%{user_id: user_id, post_id: post_id})
    |> Repo.insert(on_conflict: :nothing)
  end

  def like_post(%{does_like: false, user_id: user_id, post_id: post_id}) do
    case from(l in Like, where: l.user_id == ^user_id and l.post_id == ^post_id)
         |> Repo.delete_all() do
      {1, _} -> {:ok, :unliked}
      {0, _} -> {:ok, :already_unliked}
    end
  end

  @doc """
  Check if a user has liked a post
  """
  def user_liked_post?(user_id, post_id) do
    query =
      from l in Like,
        where: l.user_id == ^user_id and l.post_id == ^post_id

    Repo.exists?(query)
  end

  @doc """
  Get like count for a post or a comment
  """
  def get_like_count(id, :post) do
    query =
      from l in Like,
        where: l.post_id == ^id,
        select: count(l.id)

    Repo.one(query)
  end

  def get_like_count(id, :comment) do
    query =
      from l in Like,
        where: l.comment_id == ^id,
        select: count(l.id)

    Repo.one(query)
  end

  @doc """
  Get users who liked a post
  """
  def get_post_likes(post_id) do
    query =
      from l in Like,
        where: l.post_id == ^post_id,
        join: u in assoc(l, :user),
        select: u,
        order_by: [desc: l.inserted_at]

    Repo.all(query)
  end

  # ==========================================================================
  # Private Helpers
  # ==========================================================================

  # -- Shared Helpers --

  defp verify_ownership(owner_id, user_id) when owner_id == user_id, do: :ok
  defp verify_ownership(_owner_id, _user_id), do: {:error, "Unauthorized"}

  # -- Post Helpers --

  defp insert_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  defp create_media_post(_post, []), do: {:ok, []}

  defp create_media_post(post, files) do
    files
    |> Enum.with_index()
    |> Enum.reduce_while({:ok, []}, fn {file, index}, {:ok, acc} ->
      case insert_media_file(file, post.id, index) do
        {:ok, media} -> {:cont, {:ok, [media | acc]}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp insert_media_file(file, post_id, position) do
    with {:ok, file_info} <- SportsnetApi.MediaStorage.store_file(file, post_id) do
      attrs = %{
        url: file_info.url,
        media_type: file_info.media_type,
        position: position,
        post_id: post_id,
        filename: file.filename,
        file_size: file_info.file_size
      }

      %Media{}
      |> Media.changeset(attrs)
      |> Repo.insert()
    end
  end

  defp verify_edit_window(%Post{inserted_at: inserted_at}) do
    now = DateTime.utc_now()
    minutes_elapsed = DateTime.diff(now, inserted_at, :minute)

    if minutes_elapsed <= 15 do
      :ok
    else
      {:error, "Posts can only be edited within 15 minutes of creation"}
    end
  end

  defp verify_caption_changed(%Post{caption: old_caption}, new_caption) do
    old_trimmed = String.trim(old_caption || "")
    new_trimmed = String.trim(new_caption)

    if old_trimmed == new_trimmed do
      {:error, "New caption must be different from the current caption"}
    else
      :ok
    end
  end

  defp perform_edit(%Post{} = post, new_caption, current_user, ip_address) do
    Repo.transaction(fn ->
      %PostEdit{}
      |> PostEdit.changeset(%{
        old_caption: post.caption,
        new_caption: new_caption,
        user_id: current_user.id,
        post_id: post.id,
        ip_address: ip_address
      })
      |> Repo.insert!()

      post
      |> Post.changeset(%{caption: new_caption})
      |> Repo.update!()
      |> Repo.preload(:user)
      |> Map.put(:was_edited, true)
    end)
  end

  # -- Comment Helpers --

  defp insert_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end
end
