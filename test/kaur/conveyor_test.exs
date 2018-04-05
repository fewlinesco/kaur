defmodule Kaur.ConveyorTest do
  use ExUnit.Case

  alias Kaur.Conveyor

  doctest Conveyor

  def from_A_to_C do
    Conveyor.new!(
      %{
        A: &{:cont, :B, &1 + 1},
        B: &{:cont, :C, &1 + 2},
        C: &{:halt, &1 * 10}
      },
      :A
    )
  end

  defmodule SimpleGenerator do
    def run() do
      Conveyor.run(0, machine())
    end

    defp machine do
      Conveyor.new!(
        %{
          Increment: &increment/1,
          Check: &check/1,
          Finalize: &finalize/1
        },
        :Increment
      )
    end

    defp increment(state), do: {:cont, :Check, state + 1}
    defp finalize(state), do: {:halt, state}
    defp check(state) do
      if state < 10 do
        {:cont, :Increment, state}
      else
        {:cont, :Finalize, state}
      end
    end
  end

  test "Build a Conveyor without steps" do
    machine = Conveyor.new(%{}, :Start)
    assert machine == {:error, {:invalid_first_step, :Start}}
  end

  test "Build a Conveyor with invalid first step" do
    machine = Conveyor.new(%{a: &{:halt, &1}}, :Start)
    assert machine == {:error, {:invalid_first_step, :Start}}
  end

  test "An addition automator" do
    machine =
      Conveyor.new!(
        %{
          A: &{:cont, :B, &1 + 1},
          B: &{:cont, :C, &1 + 2},
          C: &{:halt, &1 + 3}
        },
        :A
      )

    assert {:ok, 6} = Conveyor.run(0, machine)
  end

  test "When a step does not exists" do
    machine =
      Conveyor.new!(
        %{
          A: &{:cont, :B, &1 + 1},
          B: &{:cont, :D, &1 + 2},
          C: &{:halt, &1 + 3}
        },
        :A
      )

    assert {:error, {:invalid_step, :D, 3}} = Conveyor.run(0, machine)
  end

  test "A simple generator" do
    assert {:ok, 10} = SimpleGenerator.run()
  end
end
