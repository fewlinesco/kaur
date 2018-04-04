defmodule KaurTest do
  use ExUnit.Case

  import ExUnit.CaptureIO

  test "tap: call the function and returns original data" do
    assert "Hello World\n" ==
             capture_io(fn ->
               assert "World" == Kaur.tap("World", fn name -> IO.puts("Hello #{name}") end)
             end)
  end
end
