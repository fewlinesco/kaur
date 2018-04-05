defmodule Kaur.ResultTest do
  use ExUnit.Case

  import ExUnit.CaptureIO
  alias Kaur.Result

  doctest Result

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
