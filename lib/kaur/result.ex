defmodule Kaur.Result do
  @moduledoc """
  Utilities for working with "result tuples".

  * `{:ok, value}`
  * `{:error, reason}`
  """

  @type t(error, success) :: {:ok, success} | {:error, error}

  @doc ~S"""
  Calls the next function only if it receives an ok tuple. Otherwise it
  skips the call and returns the error tuple.

  ## Examples

      iex> business_logic = fn(x) -> Result.ok(x * 2) end
      ...> 21 |> Result.ok() |> Result.and_then(business_logic)
      {:ok, 42}

      iex> business_logic = fn(x) -> Result.ok(x * 2) end
      ...> "oops" |> Result.error() |> Result.and_then(business_logic)
      {:error, "oops"}
  """
  @spec and_then(
          t(error, success),
          (success -> t(error, newSuccess))
        ) :: t(error, newSuccess)
        when error: var,
             success: var,
             newSuccess: var
  def and_then({:ok, data}, function), do: function.(data)
  def and_then({:error, _} = error, _function), do: error

  @doc ~S"""
  Calls the next function only if it receives two ok tuples. Otherwise it skips
  the call and returns the first error tuple.

  ## Examples

      iex> business_logic = fn(x, y) -> Result.ok(x + y) end
      ...> other_result = fn() -> Result.ok(10) end
      ...> 12 |> Result.ok() |> Result.and_then(other_result, business_logic)
      {:ok, 22}

      iex> business_logic = fn(x, y) -> Result.ok(x + y) end
      ...> result = Result.error("oops")
      ...> other_result = fn() -> Result.ok(10) end
      ...> result |> Result.and_then(other_result, business_logic)
      {:error, "oops"}

      iex> business_logic = fn(x, y) -> Result.ok(x + y) end
      ...> other_result = fn() -> Result.error("oops") end
      ...> 12 |> Result.ok() |> Result.and_then(other_result, business_logic)
      {:error, "oops"}

      iex> business_logic = fn(x, y) -> Result.ok(x + y) end
      ...> result = Result.error("oops1")
      ...> other_result = fn() -> Result.error("oops2") end
      ...> result |> Result.and_then(other_result, business_logic)
      {:error, "oops1"}
  """
  @spec and_then(
          t(error, success),
          (() -> t(otherError, otherSuccess)),
          (success, otherSuccess -> t(newError, newSuccess))
        ) :: t(error | otherError | newError, newSuccess)
        when success: var,
             newSuccess: var,
             otherSuccess: var,
             error: var,
             otherError: var,
             newError: var
  def and_then(result_a, delayed_result_b, f) do
    result_a
    |> and_then(fn x ->
      delayed_result_b.()
      |> and_then(&f.(x, &1))
    end)
  end

  @doc ~S"""
  Calls the first function if it receives an error tuple, and the second one if
  it receives an ok tuple.

  ## Examples

      iex> on_ok = fn(x) -> "X is #{x}" end
      ...> on_error = fn(e) -> "Error: #{e}" end
      ...> 42 |> Result.ok() |> Result.either(on_error, on_ok)
      "X is 42"

      iex> on_ok = fn(x) -> "X is #{x}" end
      ...> on_error = fn(e) -> "Error: #{e}" end
      ...> "oops" |> Result.error() |> Result.either(on_error, on_ok)
      "Error: oops"
  """
  @spec either(
          t(error, success),
          (error -> any),
          (success -> any)
        ) :: any
        when error: var, success: var
  def either({:ok, data}, _, on_ok), do: on_ok.(data)
  def either({:error, error}, on_error, _), do: on_error.(error)

  @doc ~S"""
  Creates a new error result tuple.

  ## Examples

      iex> Result.error("oops")
      {:error, "oops"}
  """
  @spec error(error) :: t(error, any) when error: var
  def error(value), do: {:error, value}

  @doc ~S"""
  Checks if a `result_tuple` is an error.

  ## Examples

      iex> 1 |> Result.ok() |> Result.error?
      false

      iex> 2 |>Result.error() |> Result.error?
      true
  """
  @spec error?(t(any, any)) :: boolean
  def error?({:error, _}), do: true
  def error?({:ok, _}), do: false

  @doc ~S"""
  Promotes any value to a result tuple. It excludes `nil` for the
  ok tuples.

  ## Examples

      iex> Result.from_value(nil)
      {:error, :no_value}

      iex> Result.from_value(nil, :not_found)
      {:error, :not_found}

      iex> Result.from_value(42)
      {:ok, 42}
  """
  @spec from_value(
          nil | success,
          error | :no_value
        ) :: t(error | :no_value, success)
        when success: var,
             error: var
  def from_value(value, on_nil_value \\ :no_value)
  def from_value(nil, on_nil_value), do: error(on_nil_value)
  def from_value(value, _on_nil_value), do: ok(value)

  @doc ~S"""
  Converts an `Ok` value to an `Error` value if the `predicate` is not valid.

  ## Examples

      iex> res = Result.ok(10)
      ...> Result.keep_if(res, &(&1 > 5))
      {:ok, 10}

      iex> res = Result.ok(10)
      ...> Result.keep_if(res, &(&1 > 10), "must be > of 10")
      {:error, "must be > of 10"}

      iex> res = Result.error(:no_value)
      ...> Result.keep_if(res, &(&1 > 10), "must be > of 10")
      {:error, :no_value}
  """
  @spec keep_if(
          t(error, success),
          (success -> boolean),
          newError | :invalid
        ) :: t(error | newError | :invalid, success)
        when success: var,
             error: var,
             newError: var,
             newSuccess: var
  def keep_if(result, predicate, error_message \\ :invalid)
  def keep_if({:error, _} = error, _predicate, _error_message), do: error

  def keep_if({:ok, value} = ok, predicate, error_message) do
    if predicate.(value), do: ok, else: error(error_message)
  end

  @doc ~S"""
  Calls the next function only if it receives an ok tuple. The function unwraps
  the value from the tuple, calls the next function and wraps it back into an
  ok tuple.

  ## Examples

      iex> business_logic = fn(x) -> x * 2 end
      ...> 21 |> Result.ok() |> Result.map(business_logic)
      {:ok, 42}

      iex> business_logic = fn(x) -> x * 2 end
      ...> "oops" |> Result.error() |> Result.map(business_logic)
      {:error, "oops"}
  """
  @spec map(
          t(error, success),
          (success -> newSuccess)
        ) :: t(newSuccess, error)
        when success: var,
             error: var,
             newError: var,
             newSuccess: var
  def map({:ok, data}, function), do: ok(function.(data))
  def map({:error, _} = error, _function), do: error

  @doc ~S"""
  Calls the next function only if it receives two ok tuple. The function
  unwraps the value from the tuple, calls the next function and wraps it back
  into an ok tuple.

  ## Examples

      iex> business_logic = fn(x, y) -> x * y end
      ...> result = Result.ok(21)
      ...> result |> Result.map(fn() -> {:ok, 10} end, business_logic)
      {:ok, 210}

      iex> business_logic = fn(x, y) -> x * y end
      ...> result = Result.error("oops")
      ...> result |> Result.map(fn() -> {:ok, 10} end, business_logic)
      {:error, "oops"}
  """
  @spec map(
          t(error, success),
          (() -> t(otherError, otherSuccess)),
          (success, otherSuccess -> t(error | otherError, newSuccess))
        ) :: t(error | otherError, newSuccess)
        when success: var,
             error: var,
             otherError: var,
             otherSuccess: var,
             newSuccess: var
  def map(result_a, delayed_result_b, function) do
    result_a
    |> and_then(fn x ->
      delayed_result_b.()
      |> map(&function.(x, &1))
    end)
  end

  @doc ~S"""
  Calls the next function only if it receives an error tuple. The function
  unwraps the value from the tuple, calls the next function and wraps it back
  into an error tuple.

  ## Examples

      iex> better_error = fn(_) -> "A better error message" end
      ...> 42 |> Result.ok() |> Result.map_error(better_error)
      {:ok, 42}

      iex> better_error = fn(_) -> "A better error message" end
      ...> "oops" |> Result.error() |> Result.map_error(better_error)
      {:error, "A better error message"}
  """
  @spec map_error(
          t(error, success),
          (error -> newError)
        ) :: t(newError, success)
        when success: var,
             error: var,
             newError: var
  def map_error({:ok, _} = data, _function), do: data

  def map_error({:error, _} = error, function),
    do: or_else(error, fn x -> error(function.(x)) end)

  @doc ~S"""
  Creates a new ok result tuple.

  ## Examples

      iex> Result.ok(42)
      {:ok, 42}
  """
  @spec ok(success) :: t(any, success) when success: var, error: var
  def ok(value), do: {:ok, value}

  @doc ~S"""
  Checks if a `result_tuple` is ok.

  ## Examples

      iex> 1 |> Result.ok() |> Result.ok?
      true

      iex> 2 |> Result.error() |>Result.ok?
      false
  """
  @spec ok?(t(any, any)) :: boolean
  def ok?({:ok, _}), do: true
  def ok?({:error, _}), do: false

  @doc ~S"""
  Calls the next function only if it receives an error tuple. Otherwise it
  skips the call and returns the ok tuple. It expects the function to return a
  new result tuple.

  ## Examples

      iex> business_logic = fn(_) -> {:error, "a better error message"} end
      ...> {:ok, 42} |> Result.or_else(business_logic)
      {:ok, 42}

      iex> business_logic = fn(_) -> {:error, "a better error message"} end
      ...> {:error, "oops"} |> Result.or_else(business_logic)
      {:error, "a better error message"}

      iex> default_value = fn(_) -> {:ok, []} end
      ...> {:error, "oops"} |> Result.or_else(default_value)
      {:ok, []}
  """
  @spec or_else(
          t(error, success),
          (error -> t(newError, newSuccess))
        ) :: t(success | newSuccess, error | newError)
        when success: var,
             error: var,
             newError: var,
             newSuccess: var
  def or_else({:ok, _} = data, _function), do: data
  def or_else({:error, reason}, function), do: function.(reason)

  @doc ~S"""
  Calls the next function only if it receives two error tuple. Otherwise it
  skips the call and returns the first ok tuple. It expects the function to
  return a new result tuple.

  ## Examples

      iex> business_logic = fn(_, _) -> {:error, "a better error message"} end
      ...> result = Result.ok(42)
      ...> other_result = fn() -> Result.error("oops") end
      ...> result |> Result.or_else(other_result, business_logic)
      {:ok, 42}

      iex> business_logic = fn(a, b) -> Result.error({a, b}) end
      ...> result = Result.error("oops")
      ...> other_result = fn() -> Result.error("oops2") end
      ...> result |> Result.or_else(other_result, business_logic)
      {:error, {"oops", "oops2"}}

      iex> default_value = fn(_, _) -> Result.ok([]) end
      ...> result = Result.error("oops")
      ...> other_result = fn() -> Result.ok(10) end
      ...> result |> Result.or_else(other_result, default_value)
      {:ok, 10}
  """
  @spec or_else(
          t(error, success),
          (() -> t(otherError, otherSuccess)),
          (error, otherError -> t(newError, newSuccess))
        ) ::
          t(error, success)
          | t(otherError, otherSuccess)
          | t(newError, newSuccess)
        when success: var,
             error: var,
             newError: var,
             otherError: var,
             otherSuccess: var,
             newSuccess: var
  def or_else(result_a, delayed_result_b, function) do
    result_a
    |> or_else(fn x ->
      delayed_result_b.()
      |> or_else(&function.(x, &1))
    end)
  end

  @doc ~S"""
  Converts an `Ok` value to an `Error` value if the `predicate` is valid.

  ## Examples

      iex> res = Result.ok([])
      ...> Result.reject_if(res, &Enum.empty?/1)
      {:error, :invalid}

      iex> res = Result.ok([1])
      ...> Result.reject_if(res, &Enum.empty?/1)
      {:ok, [1]}

      iex> res = Result.ok([])
      ...> Result.reject_if(res, &Enum.empty?/1, "list cannot be empty")
      {:error, "list cannot be empty"}
  """
  @spec reject_if(
          t(error, success),
          (success -> boolean),
          newError | :invalid
        ) :: t(error | newError | :invalid, success)
        when success: var,
             error: var,
             newError: var
  def reject_if(result, predicate, error_message \\ :invalid) do
    keep_if(result, &(not predicate.(&1)), error_message)
  end

  @doc ~S"""
  Transforms a list of result tuple to a result tuple containing either
  the first error tuple or an ok tuple containing the list of values.

  ### Examples

      iex> Result.sequence([Result.ok(42), Result.ok(1337)])
      {:ok, [42, 1337]}

      iex> Result.sequence([Result.ok(42), Result.error("oops"), Result.ok(1)])
      {:error, "oops"}
  """
  @spec sequence([t(any, any)]) :: t(any, any)
  def sequence(list) do
    case Enum.reduce_while(list, [], &do_sequence/2) do
      {:error, _} = error -> error
      result -> ok(Enum.reverse(result))
    end
  end

  @doc ~S"""
  Calls the next function only if it receives an ok tuple but discards the
  result. It always returns the original tuple.

  ## Examples

      iex> some_logging = fn(x) -> IO.puts "Success #{x}" end
      ...> {:ok, 42} |> Result.tap(some_logging)
      {:ok, 42}

      iex> some_logging = fn(_) -> IO.puts "Not called logging" end
      ...> {:error, "oops"} |> Result.tap(some_logging)
      {:error, "oops"}
  """
  @spec tap(
          t(error, success),
          (success -> any)
        ) :: t(error, success)
        when success: var, error: var
  def tap(data, function), do: map(data, &Kaur.tap(&1, function))

  @doc ~S"""
  Calls the next function only if it receives an error tuple but discards the
  result. It always returns the original tuple.

  ## Examples

    iex> some_logging = fn(x) -> IO.puts "Failed #{x}" end
    ...> {:error, "oops"} |> Result.tap_error(some_logging)
    {:error, "oops"}

    iex> some_logging = fn(_) -> IO.puts "Not called logging" end
    ...> {:ok, 42} |> Result.tap_error(some_logging)
    {:ok, 42}
  """
  @spec tap_error(
          t(error, success),
          (error -> any)
        ) :: t(error, success)
        when success: var, error: var
  def tap_error(data, function), do: map_error(data, &Kaur.tap(&1, function))

  @doc ~S"""
  Returns the content of an ok tuple if the value is correct. Otherwise it
  returns the default value.

  ### Examples

      iex> 42 |> Result.ok() |> Result.with_default(1337)
      42

      iex> "oops" |> Result.error() |> Result.with_default(1337)
      1337
  """
  @spec with_default(
          t(any, success),
          newSuccess
        ) :: success | newSuccess
        when success: var, newSuccess: var
  def with_default({:ok, data}, _default_data), do: data
  def with_default({:error, _}, default_data), do: default_data

  @doc ~S"""
  Wraps the argument in a `result_tuple`.

  If the argument is already a `result_tuple`, returns the `result_tuple`.

  ### Examples

      iex> 42 |> Result.ok() |> Result.wrap()
      {:ok, 42}

      iex> 42 |> Result.wrap()
      {:ok, 42}

      iex> "oops" |> Result.error() |> Result.wrap()
      {:error, "oops"}
  """
  @spec wrap(any) :: t(any, any)
  def wrap({:ok, _} = value), do: value
  def wrap({:error, _} = value), do: value
  def wrap(value), do: ok(value)

  defp do_sequence(element, elements) do
    case element do
      {:ok, value} -> {:cont, [value | elements]}
      {:error, _} -> {:halt, element}
    end
  end
end
