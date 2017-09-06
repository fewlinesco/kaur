defmodule Kaur.ResultTuple do
  @moduledoc """
  Utilities for working with "result tuples"

  * `{:ok, value}`
  * `{:error, reason}`
  """
  
  @type ok_tuple :: {:ok, any}
  @type error_tuple :: {:error, any}
  @type result_tuple :: ok_tuple | error_tuple

  @doc """
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

  @doc """
  Checks if a `result_tuple` is an error

  ## Examples
    iex> Enum.map([{:ok, 1}, {:error, 2}], &Kaur.ResultTuple.error?/1)
    [false, true]
  """
  @spec error?(result_tuple) :: boolean
  def error?({:error, _}), do: true
  def error?({:ok, _}), do: false

  @doc """
  Checks if a `result_tuple` is ok

  ## Examples
    iex> Enum.map([{:ok, 1}, {:error, 2}], &Kaur.ResultTuple.ok?/1)
    [true, false]
  """
  @spec ok?(result_tuple) :: boolean
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false
  
  @doc """
  Transforms a list of result tuple to a result tuple containing either
  the first error tuple or an ok tuple containing the list of values.

  ### Examples

    iex> Kaur.ResultTuple.sequence([{:ok, 42}, {:ok, 1337}])
    {:ok, [42, 1337]}
    iex> Kaur.ResultTuple.sequence([{:ok, 42}, {:error, "oops"}, {:ok, 1337}])
    {:error, "oops"}
  """
  @spec sequence([result_tuple]) :: ({:ok, [any()]}|{:error, any()})
  def sequence(list) do
    case Enum.reduce_while(list, [], &do_sequence/2) do
      {:error, _} = error -> error
      result -> {:ok, Enum.reverse result}
    end
  end

  defp do_sequence(element, elements) do
    case element do
      {:ok, value} -> {:cont, [value | elements]}
      {:error, _} -> {:halt, element}
    end
  end

end
