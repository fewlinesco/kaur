defmodule Kaur do
  @moduledoc """
  Generic utilities working with any kind of data.
  """

  @doc ~S"""
  Calls the next function but discards the result. It always returns the original value.

  ## Examples

    iex> business_logic = fn x -> x * 2 end
    ...> Kaur.tap(42, business_logic)
    42
  """
  def tap(value, function) do
    function.(value)

    value
  end
end
