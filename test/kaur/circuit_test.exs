defmodule Kaur.CircuitTest do
  use ExUnit.Case

  alias Kaur.Result
  alias Kaur.Circuit
  alias Kaur.Circuit.SimpleGenerator
  alias Kaur.Circuit.UserWorkflow

  doctest Circuit

  setup do
    UserWorkflow.init()
  end

  test "Build a Circuit without steps" do
    machine = Circuit.new(%{}, :Start)
    assert machine == {:error, {:invalid_first_step, :Start}}
  end

  test "Build a Circuit with invalid first step" do
    machine = Circuit.new(%{a: &{:halt, &1}}, :Start)
    assert machine == {:error, {:invalid_first_step, :Start}}
  end

  test "An addition automator" do
    machine =
      Circuit.new!(
        %{
          A: &{:cont, :B, &1 + 1},
          B: &{:cont, :C, &1 + 2},
          C: &{:halt, &1 + 3}
        },
        :A
      )

    assert {:ok, 6} = Circuit.run(0, machine)
  end

  test "When a step does not exists" do
    machine =
      Circuit.new!(
        %{
          A: &{:cont, :B, &1 + 1},
          B: &{:cont, :D, &1 + 2},
          C: &{:halt, &1 + 3}
        },
        :A
      )

    assert {:error, {:invalid_step, :D, 3}} = Circuit.run(0, machine)
  end

  test "A simple generator" do
    assert {:ok, 10} = SimpleGenerator.run()
  end

  test "When everything is ok and the user is already saved" do
    UserWorkflow.run("xvw", "xvw@gmeil.com")
    |> Result.tap(fn result ->
      assert ^result = {:ok, {{:name, "xvw"}, {:email, "xvw@gmeil.com"}}}
    end)
  end

  test "When everything is ok and the user is not saved" do
    UserWorkflow.run("Mike", "mike@freedomain.org")
    |> Result.tap(fn result ->
      assert ^result = {:ok, {{:name, "Mike"}, {:email, "mike@freedomain.org"}}}
    end)
  end

  test "When the email is invalid" do
    UserWorkflow.run("xvw", "xvw@freedomain.org")
    |> Result.tap(fn result ->
      assert ^result = {:error, :invalid_email}
    end)
  end
end
