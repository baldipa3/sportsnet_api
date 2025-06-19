defmodule SportsnetApi.Social do
  @moduledoc """
  The Social context - handles all social-related business logic
  """

  import Ecto.Query, warn: false

  alias SportsnetApi.Repo
  alias SportsnetApi.Social.Post
  alias SportsnetApi.Social.Comment

  @doc """
  Creates a new post by the user
  ## Examples

    iex> create_post(%{field: value})
    {:ok, %Post{}}

    iex> create_post(%{field: bad_value})
    {:error, %Ecto.Changeset{}}
  """
  @spec create_post(map()) :: {:ok, Post} | {:error, Ecto.Changeset.t()}
  def create_post(attrs) do
    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
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
end
