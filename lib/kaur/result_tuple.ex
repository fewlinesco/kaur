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
    ...> {:ok, 21} |> Kaur.ResultTuple.and_then(business_logic)
    {:ok, 42}

    iex> business_logic = fn x -> {:ok, x * 2} end
    ...> {:error, "oops"} |> Kaur.ResultTuple.and_then(business_logic)
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
  Calls the next function only if we have an ok tuple. The function unwraps the value
  from the tuple, call the next function and wrap it back into an ok tuple.

  ## Examples

    iex> business_logic = fn x -> x * 2 end
    ...> {:ok, 21} |> Kaur.ResultTuple.map(business_logic)
    {:ok, 42}

    iex> business_logic = fn x -> x * 2 end
    ...> {:error, "oops"} |> Kaur.ResultTuple.map(business_logic)
    {:error, "oops"}
  """
  @spec map(result_tuple, (any -> any)) :: result_tuple
  def map({:ok, data}, function), do: {:ok, function.(data)}
  def map({:error, _} = error, _function), do: error

  @doc """
  Calls the next function only if we have an error tuple. The function unwraps the value
  from the tuple, call the next function and wrap it back into an error tuple.

  ## Examples

    iex> better_error = fn _ -> "A better error message" end
    ...> {:ok, 42} |> Kaur.ResultTuple.map_error(better_error)
    {:ok, 42}

    iex> better_error = fn _ -> "A better error message" end
    ...> {:error, "oops"} |> Kaur.ResultTuple.map_error(better_error)
    {:error, "A better error message"}
  """
  @spec map_error(result_tuple, (any -> any)) :: result_tuple
  def map_error({:ok, _} = data, _function), do: data
  def map_error({:error, _} = error, function), do: or_else(error, fn x -> {:error, function.(x)} end)

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
  Calls the next function only if we have an error tuple. Otherwise we skip the call and returns the ok tuple.
  We expect the function to return a new result tuple.

  ## Examples

    iex> business_logic = fn _ -> {:error, "a better error message"} end
    ...> {:ok, 42} |> Kaur.ResultTuple.or_else(business_logic)
    {:ok, 42}

    iex> business_logic = fn _ -> {:error, "a better error message"} end
    ...> {:error, "oops"} |> Kaur.ResultTuple.or_else(business_logic)
    {:error, "a better error message"}

    iex> default_value = fn _ -> {:ok, []} end
    ...> {:error, "oops"} |> Kaur.ResultTuple.or_else(default_value)
    {:ok, []}
  """
  @spec or_else(result_tuple, (any -> result_tuple)) :: result_tuple
  def or_else({:ok, _} = data, _function), do: data
  def or_else({:error, reason}, function), do: function.(reason)

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

  @doc """
  Returns the content of an ok tuple if the value is correct. Otherwiser returns the
  default value

  ### Examples

    iex> Kaur.ResultTuple.with_default({:ok, 42}, 1337)
    42

    iex> Kaur.ResultTuple.with_default({:error, "oops"}, 1337)
    1337
  """
  @spec with_default(result_tuple, any) :: any
  def with_default({:ok, data}, _default_data), do: data
  def with_default({:error, _}, default_data), do: default_data

  defp do_sequence(element, elements) do
    case element do
      {:ok, value} -> {:cont, [value | elements]}
      {:error, _} -> {:halt, element}
    end
  end
end
