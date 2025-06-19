defmodule SportsnetApi.MediaStorage.S3 do
  @behaviour SportsnetApi.MediaStorage.Adapter

  @impl SportsnetApi.MediaStorage.Adapter
  def store_file(_file, _integer) do
    {:ok, "TODO"}
  end

  @impl SportsnetApi.MediaStorage.Adapter
  def delete_file(_file) do
    :ok
  end
end
