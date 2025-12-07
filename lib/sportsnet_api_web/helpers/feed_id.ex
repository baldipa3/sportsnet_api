defmodule SportsnetApiWeb.Helpers.FeedId do
  @moduledoc """
  Helper functions for encoding/decoding sport-city feed IDs.
  """

  @doc "Encode sport and city IDs into a feed ID"
  def encode_feed_id(sport_id, city_id) do
    Base.encode64("#{sport_id}:#{city_id}")
  end

  @doc "Decode feed ID back to sport and city IDs"
  def decode_feed_id(feed_id) do
    with {:ok, decoded} <- Base.decode64(feed_id),
         [sport_id, city_id] <- String.split(decoded, ":"),
         {sport_id_int, ""} <- Integer.parse(sport_id),
         {city_id_int, ""} <- Integer.parse(city_id) do
      {:ok, {sport_id_int, city_id_int}}
    else
      _ -> {:error, :invalid_feed_id}
    end
  end
end
