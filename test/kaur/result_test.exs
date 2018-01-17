defmodule Kaur.ResultTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  doctest Kaur.Result

  test "tap: calls the function and returns original data" do
    original = Kaur.Result.ok("World")

    assert "Hello World\n" == capture_io(fn ->
      assert original == Kaur.Result.tap(original, fn name -> IO.puts "Hello #{name}" end)
    end)
  end

  test "tap: does not call the function and returns original data" do
    original = Kaur.Result.error("Oops")

    assert "" == capture_io(fn ->
      assert original == Kaur.Result.tap(original, fn name -> IO.puts "Hello #{name}" end)
    end)
  end

  test "tap_error: does not call the function and returns original data" do
    original = Kaur.Result.ok("World")

    assert "" == capture_io(fn ->
      assert original == Kaur.Result.tap_error(original, fn name -> IO.puts "Hello #{name}" end)
    end)
  end

  test "tap_error: does call the function and returns original data" do
    original = Kaur.Result.error("Oops")

    assert "Hello Oops\n" == capture_io(fn ->
      assert original == Kaur.Result.tap_error(original, fn name -> IO.puts "Hello #{name}" end)
    end)
  end
end
