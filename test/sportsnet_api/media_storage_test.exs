defmodule SportsnetApi.MediaStorageTest do
  use SportsnetApi.DataCase

  alias SportsnetApi.MediaStorage

  describe "store_file/2" do
    setup do
      test_dir = "tmp/test_uploads"
      File.rm_rf(test_dir)
      File.mkdir_p!(test_dir)

      on_exit(fn ->
        "priv/static/images/"
        |> File.ls!()
        |> Enum.filter(&String.contains?(&1, "post_123"))
        |> Enum.each(fn file ->
          File.rm("priv/static/images/#{file}")
        end)
      end)

      :ok
    end

    test "stores a valid image file" do
      tmp_path = "tmp/test_image.jpg"
      File.write!(tmp_path, "fake image data")

      upload = %Plug.Upload{
        filename: "test_image.jpg",
        path: tmp_path,
        content_type: "image/jpeg"
      }

      assert {:ok,  file_info} = MediaStorage.store_file(upload, 123)
      assert String.contains?(file_info.url, "post_123_test_image.jpg")

      File.rm!(tmp_path)
    end

    test "reject unsupported file extensions" do
      tmp_path = "tmp/document.pdf"
      File.write!(tmp_path, "fake pdf data")

      upload = %Plug.Upload{
        filename: "document.pdf",
        path: tmp_path,
        content_type: "application/pdf"
      }

      assert {:error,  reason} = MediaStorage.store_file(upload, 123)
      assert reason == "Unsupported file extension .pdf"

      File.rm!(tmp_path)
    end

    test "reject oversized files" do
      tmp_path = "tmp/huge.jpg"
      File.write!(tmp_path, String.duplicate("x", 11_000_000))

      upload = %Plug.Upload{
        filename: "huge.jpg",
        path: tmp_path,
        content_type: "image/jpeg"
      }

      assert {:error,  reason} = MediaStorage.store_file(upload, 123)
      assert reason == "File too large. Max size: 10000000 bytes"

      File.rm!(tmp_path)
    end
  end
end
