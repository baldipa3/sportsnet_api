defmodule SportsnetApi.Helpers.ErrorHelpers do
  @moduledoc """
  Common error formatting utilities used throughout the application.
  """

  @doc """
  Formats changeset errors into a list of error maps.
  """
  def format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, val}, acc ->
        String.replace(acc, "%{#{key}}", to_string(val))
      end)
    end)
    |> Enum.map(fn {field, messages} ->
      "#{field} #{Enum.join(messages, ", ")}"
    end)
    |> Enum.map(&%{message: &1})
  end
end
