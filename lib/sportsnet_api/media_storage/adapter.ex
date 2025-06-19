defmodule SportsnetApi.MediaStorage.Adapter do
  @moduledoc """
  Behaviour for media storage implementations.

  This behaviour defines the interface for storing and managing media files
  across different storage backends (local filesystem, S3, etc.).

  ## Callbacks

  - `store_file/2` - Stores a single uploaded file and returns its public URL
  - `delete_file/1` - Deletes a file using its public URL

  ## Examples

      defmodule MyApp.Storage.Local do
        @behaviour SportsnetApi.MediaStorage.Behaviour

        def store_file(upload, post_id) do
          # Implementation for local storage
        end

        def delete_file(url) do
          # Implementation for local deletion
        end
      end
  """

  @doc """
  Stores an uploaded file for a specific post.

  ## Parameters
  - `upload` - A `Plug.Upload` struct containing the file data
  - `post_id` - Integer ID of the post this media belongs to

  ## Returns
  - `{:ok, public_url}` - Success with the public URL to access the file
  - `{:error, reason}` - Error with description of what went wrong
  """
  @callback store_file(Plug.Upload.t(), integer()) :: {:ok, String.t()} | {:error, String.t()}

  @doc """
  Deletes a previously stored file.

  ## Parameters
  - `public_url` - The public URL returned from `store_file/2`

  ## Returns
  - `:ok` - File successfully deleted
  - `{:error, reason}` - Error with description of what went wrong
  """
  @callback delete_file(String.t()) :: :ok | {:error, String.t()}
end
