defmodule SportsnetApi.MediaStorage do
  @moduledoc """
  Handles file storage and retrieval for media uploads across the application.

  This module provides a unified interface for storing files that automatically
  switches between local file storage (development) and cloud storage like S3
  (production) based on application configuration.

  ## Usage

      # Store an uploaded file
      {:ok, url} = MediaStorage.store_file(file, post_id)

      # Delete a file
      :ok = MediaStorage.delete_file(url)


  ## Storage Backends

  - **Local**: Files stored in `priv/static/uploads/` and served by Phoenix
  - **S3**: Files stored in AWS S3 bucket (production)

  The storage backend is configured via application config and can be switched
  without changing any calling code.

  ## File Organization

  Files are organized in a hierarchical structure to ensure scalability:
  - Local: `priv/static/uploads/posts/{post_id}/{timestamp}_{filename}`
  - S3: `posts/{post_id}/{timestamp}_{filename}`

  ## Error Handling

  All functions return `{:ok, result}` or `{:error, reason}` tuples for
  consistent error handling across the application.
  """
  @adapter Application.compile_env(:sportsnet_api, __MODULE__)[:adapter]
  @max_image_size 10_000_000
  @max_video_size 100_000_000
  # @max_video_duration 300
  @image_extensions ~w(.jpg .jpeg .png .gif .webp)
  @video_extensions ~w(.mp4 .mov .avi .webm)

  @doc """
  Stores an uploaded file and returns its public URL.

  Validates the file type and size before delegating to the configured storage adapter.
  Supports images (#{Enum.join(@image_extensions, ", ")}) and videos (#{Enum.join(@video_extensions, ", ")}).

  ## Parameters

  * `file` - A `Plug.Upload` struct containing the uploaded file
  * `post_id` - Integer ID of the post this media belongs to

  ## Returns

  * `{:ok, public_url}` - Success with the public URL to access the stored file
  * `{:error, reason}` - Error with description of validation failure or storage issue

  ## Examples

    iex> upload = %Plug.Upload{filename: "photo.jpg", path: "/tmp/upload"}
    iex> MediaStorage.store_file(upload, 123)
    {:ok, "/images/posts/123/1640995200_photo.jpg"}

    iex> upload = %Plug.Upload{filename: "document.pdf", path: "/tmp/upload"}
    iex> MediaStorage.store_file(upload, 123)
    {:error, "Unsupported file extension .pdf"}

  ## Validation Rules

  * **Images**: Maximum size #{@max_image_size} bytes
  * **Videos**: Maximum size #{@max_video_size} bytes
  * **Extensions**: Only files with allowed extensions are accepted

  """

  def store_file(file, post_id) do
    with {:ok, type} <- validate_file_type(file),
         :ok <- validate_file_size(file, type),
         :ok <- validate_duration(file, type) do
      @adapter.store_file(file, post_id)
    end
  end

  defp validate_file_type(%Plug.Upload{filename: filename}) do
    ext = filename |> Path.extname() |> String.downcase()

    cond do
      ext in @image_extensions -> {:ok, :image}
      ext in @video_extensions -> {:ok, :video}
      true -> {:error, "Unsupported file extension #{ext}"}
    end
  end

  defp validate_file_size(%Plug.Upload{path: path}, type) do
    {:ok, %File.Stat{size: size}} = File.stat(path)

    max_size = case type do
      :image -> @max_image_size
      :video -> @max_video_size
    end

    if size <= max_size do
      :ok
    else
      {:error, "File too large. Max size: #{max_size} bytes"}
    end
  end

  defp validate_duration(_file, :image), do: :ok
  defp validate_duration(_file, :video) do
    # TODO
    :ok
  end
end
