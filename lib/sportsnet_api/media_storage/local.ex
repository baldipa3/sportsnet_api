defmodule SportsnetApi.MediaStorage.Local do
  @behaviour SportsnetApi.MediaStorage.Adapter

  @impl SportsnetApi.MediaStorage.Adapter
  def store_file(%Plug.Upload{filename: filename, path: source_path}, post_id) do
    dest_dir = "priv/static/images"
    File.mkdir_p!(dest_dir)

    timestamp = System.system_time(:second)
    dest_filename = "#{timestamp}_post_#{post_id}_#{filename}"
    dest_path = Path.join(dest_dir, dest_filename)
    url = "http://localhost:4000/images/#{dest_filename}"

    case File.cp(source_path, dest_path) do
      :ok -> {:ok, url}

      {:error, reason} -> {:error, "Failed to store file: #{reason}"}
    end
  end

  @impl SportsnetApi.MediaStorage.Adapter
  def delete_file(_file) do
    {:error, "Delete not implemented yet"}
  end
end
