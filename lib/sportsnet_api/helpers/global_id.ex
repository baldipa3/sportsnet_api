defmodule SportsnetApi.Helpers.GlobalId do
  @moduledoc """
  Global Object Identification standard implementation to comply with Relay requirements of global ids
  Encodes/decodes global IDs using Base64 encoding of "TypeName:localId"
  """

  @doc """
  Encode a type and local ID into a standard Global ID

  ## Examples
      iex> GlobalId.encode("Country", 5)
      "Q291bnRyeTo1"

      iex> GlobalId.encode("Sport", 8)
      "U3BvcnQ6OA=="
  """

  def encode(type_name, local_id) do
    "#{type_name}:#{local_id}"
    |> Base.encode64()
  end


  @doc """
  Decode a Global ID back to type and local ID

  ## Examples
      iex> GlobalId.decode("Q291bnRyeTo1")
      {:ok, "Country", "5"}

      iex> GlobalId.decode("invalid")
      {:error, "Invalid Global ID"}
  """

  def decode(global_id) do
    case Base.decode64(global_id) do
      {:ok, decoded} ->
        case String.split(decoded, ":", parts: 2) do
          [type_name, local_id] -> {:ok, type_name, local_id}
          _ -> {:error, "Invalid Global ID format"}
        end
      :error ->
        {:error, "Invalid Global ID"}
    end
  end

  @doc """
  Decode and return just the local ID as integer
  """
  def decode_id(global_id) do
    case decode(global_id) do
      {:ok, _type, local_id} -> String.to_integer(local_id)
      {:error, _} -> nil
    end
  end
end
