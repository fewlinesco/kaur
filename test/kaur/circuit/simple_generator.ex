defmodule Kaur.Circuit.SimpleGenerator do
  alias Kaur.Circuit

  def run() do
    Circuit.run(0, machine())
  end

  defp machine do
    Circuit.new!(
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
