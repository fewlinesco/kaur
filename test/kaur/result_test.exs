defmodule Kaur.ResultTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  alias Kaur.Result

  doctest Result

  test "and_then/2: with ok" do
    result =
      Result.ok(10)
      |> Result.and_then(&Result.ok(&1 + 1))

    assert {:ok, 11} == result
  end

  test "and_then/2: with error" do
    result =
      Result.error(:invalid_data)
      |> Result.and_then(&Result.ok(&1 + 1))

    assert {:error, :invalid_data} == result
  end

  test "and_then/3: with two ok's" do
    delayed_result = fn -> Result.ok(12) end

    result =
      Result.ok(10)
      |> Result.and_then(delayed_result, &Result.ok(&1 + &2))

    assert {:ok, 22} == result
  end

  test "and_then/3: with an error (1)" do
    delayed_result = fn -> Result.error(:invalid_data) end

    result =
      Result.ok(10)
      |> Result.and_then(delayed_result, &Result.ok(&1 + &2))

    assert {:error, :invalid_data} == result
  end

  test "Either with ok" do
    result =
      Result.ok(10)
      |> Result.either(&{:failure, &1}, &{:success, &1})

    assert {:success, 10} == result
  end

  test "Either with error" do
    result =
      Result.error(:oops)
      |> Result.either(&{:failure, &1}, &{:success, &1})

    assert {:failure, :oops} == result
  end

  test "and_then/3: with an error (2)" do
    delayed_result = fn -> Result.ok(10) end

    result =
      Result.error(:invalid_data)
      |> Result.and_then(delayed_result, &Result.ok(&1 + &2))

    assert {:error, :invalid_data} == result
  end

  test "from_value: when the data is not nil" do
    result = Result.from_value(10)

    assert {:ok, 10} == result
  end

  test "from_value: when the data is nil" do
    result = Result.from_value(nil)

    assert {:error, :no_value} == result
  end

  test "from_value: when the data is nil with custom error" do
    result = Result.from_value(nil, "oops")

    assert {:error, "oops"} == result
  end

  test "keep_if: test with valid predicate" do
    result =
      Result.ok(10)
      |> Result.keep_if(&(&1 > 5))

    assert {:ok, 10} == result
  end

  test "keep_if: test with invalid predicate" do
    result =
      Result.ok(10)
      |> Result.keep_if(&(&1 < 5))

    assert {:error, :invalid} == result
  end

  test "keep_if: test with invalid predicate and custom error" do
    result =
      Result.ok(10)
      |> Result.keep_if(&(&1 < 5), "oops")

    assert {:error, "oops"} == result
  end

  test "tap: calls the function and returns original data" do
    original = Result.ok("World")

    assert "Hello World\n" ==
             capture_io(fn ->
               assert original == Result.tap(original, fn name -> IO.puts("Hello #{name}") end)
             end)
  end

  test "tap: does not call the function and returns original data" do
    original = Result.error("Oops")

    assert "" ==
             capture_io(fn ->
               assert original == Result.tap(original, fn name -> IO.puts("Hello #{name}") end)
             end)
  end

  test "tap_error: does not call the function and returns original data" do
    original = Result.ok("World")

    assert "" ==
             capture_io(fn ->
               assert original ==
                        Result.tap_error(original, fn name -> IO.puts("Hello #{name}") end)
             end)
  end

  test "tap_error: does call the function and returns original data" do
    original = Result.error("Oops")

    assert "Hello Oops\n" ==
             capture_io(fn ->
               assert original ==
                        Result.tap_error(original, fn name -> IO.puts("Hello #{name}") end)
             end)
  end
end
