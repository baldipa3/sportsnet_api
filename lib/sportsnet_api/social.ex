defmodule SportsnetApi.Social do
  @moduledoc """
  The Social context - handles all social-related business logic
  """

  import Ecto.Query, warn: false

  alias SportsnetApi.Repo
  alias SportsnetApi.Social.Post
  alias SportsnetApi.Social.Comment
  alias SportsnetApi.Social.Media

  @doc """
  Creates a new post by the user, optionally with media files

  ## Parameters
  - `attrs` - Map containing post attributes (caption, user_id, sport_id, city_id)
  - `files` - List of Plug.Upload structs for media files (optional, defaults to [])

  ## Returns
  - `{:ok, {post, media_records}}` - Success with post and list of associated media records
  - `{:error, reason}` - Error with changeset (for post validation) or error message (for file operations)

  ## Examples

      # Create post without media
      iex> create_post(%{caption: "Hello world", user_id: 1, sport_id: 1, city_id: 1})
      {:ok, {%Post{}, []}}

      # Create post with media files
      iex> files = [%Plug.Upload{filename: "photo.jpg", ...}]
      iex> create_post(%{caption: "Check this out!", user_id: 1, sport_id: 1, city_id: 1}, files)
      {:ok, {%Post{}, [%Media{}]}}

      # Invalid post attributes
      iex> create_post(%{caption: nil, user_id: nil})
      {:error, %Ecto.Changeset{}}

      # Invalid file type
      iex> files = [%Plug.Upload{filename: "document.pdf", ...}]
      iex> create_post(%{caption: "Valid post", user_id: 1, sport_id: 1, city_id: 1}, files)
      {:error, "Unsupported file extension .pdf"}
  """
  @spec create_post(map(), list()) :: {:ok, Post} | {:error, Ecto.Changeset.t()}
  def create_post(attrs, files \\ []) do
    Repo.transaction(fn ->
      with {:ok, post} <- insert_post(attrs),
           {:ok, media_records} <- create_media_post(post, files) do
        {post, media_records}
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @doc """
  Creates a new Post Comment by the user
  ## Examples

    iex> create_comment(%{field: value})
    {:ok, %Comment{}}

    iex> create_comment(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """
  @spec create_comment(map()) :: {:ok, Comment} | {:error, Ecto.Changeset.t()}
  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

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
end
