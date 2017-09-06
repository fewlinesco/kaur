defmodule Kaur.ResultTuple do
  @moduledoc ~S"""
  Utilities for working with "result tuples"

  * `{:ok, value}`
  * `{:error, reason}`
  """

  @type ok_tuple :: {:ok, any}
  @type error_tuple :: {:error, any}
  @type result_tuple :: ok_tuple | error_tuple

  @doc ~S"""
  Calls the next function only if we have an ok tuple. Otherwise we skip the call and
  returns the error tuple

  ## Examples

    iex> business_logic = fn x -> {:ok, x * 2} end
    iex> {:ok, 21} |> Kaur.ResultTuple.and_then(business_logic)
    {:ok, 42}
    iex> {:error, "oops"} |> Kaur.ResultTuple.and_then(business_logic)
    {:error, "oops"}
  """
  @spec and_then(result_tuple, (any -> result_tuple)) :: result_tuple
  def and_then({:ok, data}, function), do: function.(data)
  def and_then({:error, _} = error, _function), do: error

  @doc ~S"""
  Transforms a list of result tuple to a result tuple containing either
  the first error tuple or an ok tuple containing the list of values.

  ### Examples

    iex> Kaur.ResultTuple.sequence([{:ok, 42}, {:ok, 1337}])
    {:ok, [42, 1337]}
    iex> Kaur.ResultTuple.sequence([{:ok, 42}, {:error, "oops"}, {:ok, 1337}])
    {:error, "oops"}
  """
  @spec sequence([result_tuple]) :: ({:ok, [any()]}|{:error, any()})
  def sequence(list), do: do_sequence(list, [])

  defp do_sequence([], new_list), do: {:ok, Enum.reverse(new_list)}
  defp do_sequence([{:ok, value} | nexts], new_list), do: do_sequence(nexts, [value | new_list])
  defp do_sequence([{:error, _reason} = error | _nexts], _new_list), do: error
end
