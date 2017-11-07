defmodule Kaur.Result do
  @moduledoc """
  Utilities for working with "result tuples"

  * `{:ok, value}`
  * `{:error, reason}`
  """
  @type typed_ok_tuple(type) :: {:ok, type}
  @type ok_tuple :: typed_ok_tuple(any)
  @type error_tuple :: {:error, any}
  @type typed_result_tuple(type) :: typed_ok_tuple(type) | error_tuple
  @type result_tuple :: typed_result_tuple(any)

  @doc """
  Calls the next function only if we have an ok tuple. Otherwise we skip the call and
  returns the error tuple

  ## Examples

      iex> business_logic = fn x -> Kaur.Result.ok(x * 2) end
      ...> 21 |> Kaur.Result.ok |> Kaur.Result.and_then(business_logic)
      {:ok, 42}

      iex> business_logic = fn x -> Kaur.Result.ok(x * 2) end
      ...> "oops" |> Kaur.Result.error |> Kaur.Result.and_then(business_logic)
      {:error, "oops"}
  """
  @spec and_then(result_tuple, (any -> result_tuple)) :: result_tuple
  def and_then({:ok, data}, function), do: function.(data)
  def and_then({:error, _} = error, _function), do: error

  @doc """
  Calls the first function if we have an error tuple, and the second one if we have an ok
  tuple.

  ## Examples

      iex> on_ok = fn x -> "X is \#{x}" end
      ...> on_error = fn e -> "Error: \#{e}" end
      ...> 42 |> Kaur.Result.ok |> Kaur.Result.either(on_error, on_ok)
      "X is 42"

      iex> on_ok = fn x -> "X is \#{x}" end
      ...> on_error = fn e -> "Error: \#{e}" end
      ...> "oops" |> Kaur.Result.error |> Kaur.Result.either(on_error, on_ok)
      "Error: oops"
  """
  @spec either(result_tuple, (any -> any), (any -> any)) :: any
  def either({:ok, data}, _, on_ok), do: on_ok.(data)
  def either({:error, error}, on_error, _), do: on_error.(error)

  @doc """
  Create a new error result tuple

  ## Examples

      iex> Kaur.Result.error("oops")
      {:error, "oops"}
  """
  @spec error(any) :: error_tuple
  def error(value), do: {:error, value}

  @doc """
  Checks if a `result_tuple` is an error

  ## Examples

      iex> 1 |> Kaur.Result.ok |> Kaur.Result.error?
      false

      iex> 2 |>Kaur.Result.error |> Kaur.Result.error?
      true
  """
  @spec error?(result_tuple) :: boolean
  def error?({:error, _}), do: true
  def error?({:ok, _}), do: false

  @doc """
  Promotes any value to a result tuple. We excludes `nil` for the
  ok tuples.

  ## Examples

      iex> Kaur.Result.from_value(nil)
      {:error, :no_value}

      iex> Kaur.Result.from_value(42)
      {:ok, 42}
  """
  @spec from_value(any) :: result_tuple
  def from_value(nil), do: error(:no_value)
  def from_value(value), do: ok(value)

  @doc """
  Calls the next function only if we have an ok tuple. The function unwraps the value
  from the tuple, call the next function and wrap it back into an ok tuple.

  ## Examples

      iex> business_logic = fn x -> x * 2 end
      ...> 21 |> Kaur.Result.ok |> Kaur.Result.map(business_logic)
      {:ok, 42}

      iex> business_logic = fn x -> x * 2 end
      ...> "oops" |> Kaur.Result.error |> Kaur.Result.map(business_logic)
      {:error, "oops"}
  """
  @spec map(result_tuple, (any -> any)) :: result_tuple
  def map({:ok, data}, function), do: ok(function.(data))
  def map({:error, _} = error, _function), do: error

  @doc """
  Calls the next function only if we have an error tuple. The function unwraps the value
  from the tuple, call the next function and wrap it back into an error tuple.

  ## Examples

      iex> better_error = fn _ -> "A better error message" end
      ...> 42 |> Kaur.Result.ok |> Kaur.Result.map_error(better_error)
      {:ok, 42}

      iex> better_error = fn _ -> "A better error message" end
      ...> "oops" |> Kaur.Result.error |> Kaur.Result.map_error(better_error)
      {:error, "A better error message"}
  """
  @spec map_error(result_tuple, (any -> any)) :: result_tuple
  def map_error({:ok, _} = data, _function), do: data
  def map_error({:error, _} = error, function), do: or_else(error, fn x -> error(function.(x)) end)

  @doc """
  Create a new ok result tuple

  ## Examples

      iex> Kaur.Result.ok(42)
      {:ok, 42}
  """
  @spec ok(any) :: ok_tuple
  def ok(value), do: {:ok, value}

  @doc """
  Checks if a `result_tuple` is ok

  ## Examples

      iex> 1 |> Kaur.Result.ok |> Kaur.Result.ok?
      true

      iex> 2 |> Kaur.Result.error |>Kaur.Result.ok?
      false
  """
  @spec ok?(result_tuple) :: boolean
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  @doc """
  Calls the next function only if we have an error tuple. Otherwise we skip the call and returns the ok tuple.
  We expect the function to return a new result tuple.

  ## Examples

      iex> business_logic = fn _ -> {:error, "a better error message"} end
      ...> {:ok, 42} |> Kaur.Result.or_else(business_logic)
      {:ok, 42}

      iex> business_logic = fn _ -> {:error, "a better error message"} end
      ...> {:error, "oops"} |> Kaur.Result.or_else(business_logic)
      {:error, "a better error message"}

      iex> default_value = fn _ -> {:ok, []} end
      ...> {:error, "oops"} |> Kaur.Result.or_else(default_value)
      {:ok, []}
  """
  @spec or_else(result_tuple, (any -> result_tuple)) :: result_tuple
  def or_else({:ok, _} = data, _function), do: data
  def or_else({:error, reason}, function), do: function.(reason)

  @doc """
  Transforms a list of result tuple to a result tuple containing either
  the first error tuple or an ok tuple containing the list of values.

  ### Examples

      iex> Kaur.Result.sequence([Kaur.Result.ok(42), Kaur.Result.ok(1337)])
      {:ok, [42, 1337]}

      iex> Kaur.Result.sequence([Kaur.Result.ok(42), Kaur.Result.error("oops"), Kaur.Result.ok(1337)])
      {:error, "oops"}
  """
  @spec sequence([result_tuple]) :: ({:ok, [any()]}|{:error, any()})
  def sequence(list) do
    case Enum.reduce_while(list, [], &do_sequence/2) do
      {:error, _} = error -> error
      result -> ok(Enum.reverse result)
    end
  end

  @doc """
  Returns the content of an ok tuple if the value is correct. Otherwiser returns the
  default value

  ### Examples

      iex> 42 |> Kaur.Result.ok |> Kaur.Result.with_default(1337)
      42

      iex> "oops" |> Kaur.Result.error |> Kaur.Result.with_default(1337)
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
