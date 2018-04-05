defmodule Kaur.Conveyor do
  @moduledoc """
  **Conveyor** allows the creation of embeddable finite state machine.

  Unlike [gen_statem](http://erlang.org/doc/man/gen_statem.html),
  it can easily be used in a function.

  A conveyor belt is simply a collection of **steps**.
  Each step has a **name** and a **callback** function.
  The callback function of a step can return:

  - `{:cont, new_step, new_state}`: who will call the next step by transmitting
     to him the new state;
  - `{:halt, final_state}`: who will return the final state (wrapped into a
     `Result.t`).

  Once defined, the conveyor can be run, with the initial value of the state.

  ### For example

  ```elixir
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
  ```

      iex> Conveyor.run(1, from_A_to_C())
      {:ok, 40}

  We can integrate more logic in the callbacks of the steps. For example:

  ```elixir
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
  ```
  """

  alias Kaur.Result

  @typedoc ~S"""
  Defines the result of a step.

  - `{:cont, next_step, new_state}` : go the next step (and update the state)
  - `{:halt, final_state}` : interrupts the conveyor
  """
  @type step_result :: {:halt, any} | {:cont, atom, any}

  @typedoc ~S"""
  Defines the type of a step (as a function from any to a result).
  """
  @type step :: (any -> step_result)

  @typedoc ~S"""
  Each step of the Conveyor, defined as a Map.
  """
  @type vertices :: %{required(atom) => step}

  @typedoc ~S"""
  The main type of a Conveyor.
  """
  @type t :: %__MODULE__{vertices: vertices, first_step: atom}

  @typedoc ~S"""
  Defines the different potentials errors.
  """
  @type error ::
          {:invalid_first_step, atom}
          | {:invalid_step, atom, any}

  defstruct [:vertices, :first_step]

  @doc ~S"""
  Helper for creating a Cont step.

  ## Examples

      iex> Conveyor.cont(:Start, 10)
      {:cont, :Start, 10}
  """
  @spec cont(atom, any) :: {:cont, atom, any}
  def cont(next_step, state) do
    {:cont, next_step, state}
  end

  @doc ~S"""
  Helper for creating an Halt step.

  ## Examples

      iex> Conveyor.halt(25)
      {:halt, 25}
  """
  @spec halt(any) :: {:halt, any}
  def halt(state) do
    {:halt, state}
  end

  @doc ~S"""
  Creates a new Conveyor. This function could fail.
  """
  @spec new!(vertices, atom) :: t
  def new!(%{} = vertices, first_step) do
    checked_vertices = Enum.into(vertices, %{}, &check_fun/1)

    cond do
      Map.has_key?(checked_vertices, first_step) ->
        %__MODULE__{
          vertices: checked_vertices,
          first_step: first_step
        }

      true ->
        throw({:invalid_first_step, first_step})
    end
  end

  @doc ~S"""
  Creates a new Conveyor and wrap it into a Result.t
  """
  @spec new(vertices, atom) :: Result.t(error, t)
  def new(vertices, first_step) do
    try do
      Result.ok(new!(vertices, first_step))
    catch
      error -> Result.error(error)
    end
  end

  @doc ~S"""
  Run a Conveyor with a given Input.

  ## Example

      iex> machine =
      ...>  Conveyor.new!(
      ...>    %{
      ...>      A: &{:cont, :B, &1 + 1},
      ...>      B: &{:cont, :C, &1 + 2},
      ...>      C: &{:halt, &1 + 3}
      ...>    },
      ...>    :A
      ...>)
      ...> Conveyor.run(0, machine)
      {:ok, 6}
  """
  @spec run(any, t) :: Result.t(error, any)
  def run(input, conveyor) do
    conveyor.first_step
    |> process_run(input, conveyor)
  end

  defp check_fun({_, fun} = step) when is_function(fun, 1) do
    step
  end

  defp process_run(step, state, conveyor) do
    case Map.fetch(conveyor.vertices, step) do
      :error ->
        Result.error({:invalid_step, step, state})

      {:ok, callback} ->
        case callback.(state) do
          {:halt, new_state} ->
            Result.ok(new_state)

          {:cont, new_step, new_state} ->
            process_run(new_step, new_state, conveyor)
        end
    end
  end
end
