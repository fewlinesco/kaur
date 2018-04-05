defmodule Kaur.Circuit do
  @moduledoc """
  Expose a data structure to build embeddable finite state machines.

  A finite state machine must be defined and can then be used with an input
  value.

  The main difference with a conventional pipeline (or a result pipeline) is
  the ability to move from one stage to another easily (forward or backward).

  ## Taxonomy of a state machine

  It is a struct that exposes a list of vertices (in the form of Map, the key
  being the state label and its value being a callback function) and the first
  label to execute.

  A callback function must return one of these two values:

  - `{:cont, new_label, new_state}`: Indicates that the callback passes the hand
     to another step.

  -  `{:halt, final_state}` : Stops the execution of the machine and returns
     the last state (wrapped in a `Result`)

  ## For example
  Let's imagine a very simple Workflow to deal with users.
  (The workflow is not "safe", it is just a P.O.C!)

  - An user is characterized by a `name` and an `email`;
  - When an user tries to connect (**A**);
    - We check the username (**B**). If it exists, check his email (**C**);
    - If it does not exist, it is created (**D**);
  - We connect the user (**E**);
  - We We say Hello (**F**);
  - User exists, but email is invalid (**G**)

  This workflow could be represented in this way :

  ```
  A -> B -> C -> E -> F # Normal case, everything is good
  A -> B -> D -> A # When the user does not exists
  A -> B -> C -> G # When the user exists but his email is invalid
  ```

  ### Implementations of different states

  To be more understandable, let's rename our letters explicitly:

  - `A` and `B` -> `:Login`
  - `C` and `G` -> `:UserExists`
  - `D` -> `:SaveUser`
  - `E` -> `:Connect`
  - `F` -> `:SayHello`

  This mapping gives us this machine :

  ```elixir
  Circuit.new!(
    %{
      Login: &login/1,
      UserExists: &user_exists/1,
      Connection: &connection/1,
      SaveUser: &save_user/1,
      SayHello: &say_hello/1
    },
    :Login # Login is the "first step" of the machine
  )
  ```

  The first step is to find a user by name:

  ```elixir
  defp login({username, email}) do
    case get_by_name(username) do
      {:ok, user} -> {:cont, :UserExists, {user, email}}
      {:error, :unknown_user} -> {:cont, :SaveUser, {username, email}}
      {:error, err} -> {:halt, Result.error(err)}
    end
  end
  ```

  - If we find a user, we send the data to `:UserExists`;
  - if we do not find a user we send the data to `:SaveUser`;
  - else, we have an error, and we stop the machine.

  If our user does not exists, we can just add him into the
  Database and restart the procedure :

  ```elixir
  defp save_user({username, email}) do
    :ets.insert(:users, {{:name, username}, {:email, email}})
    IO.puts("user saved")
    {:cont, :Login, {username, email}} # Come back to the first step
  end
  ```

  On the other hand, if the user exists, check that his email address
  corresponds to the one in the Database:

  ```elixir
  defp user_exists({{_, {:email, email}} = user, email}) do
    {:cont, :Connection, user}
  end
  defp user_exists(_), do: {:halt, Result.error(:invalid_email)}
  ```

  If the emails do not match, the user can not be connected, and the machine is
  interrupted. Otherwise, the user is sent to the next step, `:Connect`.

  ```elixir
  defp connection(user) do
    IO.puts("User connected")
    {:cont, :SayHello, user}
  end

  defp say_hello({{:name, name}, _} = user) do
    IO.puts("Hello \#{name}")
    {:halt, Result.ok(user)}
  end
  ```

  The last two steps are accessory. They can be closely related to what is done
  in a conventional pipeline.

  That's all folks!

  ### Complete workflow

  ```elixir
  defmodule Kaur.Circuit.UserWorkflow do
    alias Kaur.Circuit
    alias Kaur.Result

    def init do
      :ets.new(:users, [:set, :named_table])
      :ets.insert(:users, {{:name, "xvw"}, {:email, "xvw@gmeil.com"}})
      :ok
    end

    def run(username, email) do
      {username, email}
      |> Circuit.run(workflow())
    end

    defp workflow do
      Circuit.new!(
        %{
          Login: &login/1,
          UserExists: &user_exists/1,
          Connection: &connection/1,
          SaveUser: &save_user/1,
          SayHello: &say_hello/1
        },
        :Login
      )
    end

    defp connection(user) do
      IO.puts("User connected")
      {:cont, :SayHello, user}
    end

    defp get_by_name(name) do
      case :ets.lookup(:users, {:name, name}) do
        [user] -> Result.ok(user)
        [] -> Result.error(:unknown_user)
        _ -> Result.error(:multiple_user_with_same_name)
      end
    end

    defp login({username, email}) do
      case get_by_name(username) do
        {:ok, user} -> {:cont, :UserExists, {user, email}}
        {:error, :unknown_user} -> {:cont, :SaveUser, {username, email}}
        {:error, err} -> {:halt, Result.error(err)}
      end
    end

    defp save_user({username, email}) do
      :ets.insert(:users, {{:name, username}, {:email, email}})
      IO.puts("user saved")
      {:cont, :Login, {username, email}}
    end

    defp say_hello({{:name, name}, _} = user) do
      IO.puts("Hello \#{name}")
      {:halt, Result.ok(user)}
    end

    defp user_exists({{_, {:email, email}} = user, email}) do
      {:cont, :Connection, user}
    end

    defp user_exists(_) do
      {:halt, Result.error(:invalid_email)}
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
  @type step_result ::
          {:halt, any}
          | {:cont, atom, any}

  @typedoc ~S"""
  Defines the type of a step (as a function from any to a result).
  """
  @type step :: (any -> step_result)

  @typedoc ~S"""
  Each step of the Circuit, defined as a Map.
  """
  @type vertices :: %{required(atom) => step}

  @typedoc ~S"""
  The main type of a Circuit.
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

      iex> Circuit.cont(:Start, 10)
      {:cont, :Start, 10}
  """
  @spec cont(atom, any) :: {:cont, atom, any}
  def cont(next_step, state) do
    {:cont, next_step, state}
  end

  @doc ~S"""
  Helper for creating an Halt step.

  ## Examples

      iex> Circuit.halt(25)
      {:halt, 25}
  """
  @spec halt(any) :: {:halt, any}
  def halt(state) do
    {:halt, state}
  end

  @doc ~S"""
  Creates a new Machine. This function could fail.
  """
  @spec new!(vertices, atom) :: t
  def new!(%{} = vertices, first_step) do
    checked_vertices = Enum.into(vertices, %{}, &check_fun/1)

    if Map.has_key?(checked_vertices, first_step) do
      %__MODULE__{
        vertices: checked_vertices,
        first_step: first_step
      }
    else
      throw({:invalid_first_step, first_step})
    end
  end

  @doc ~S"""
  Creates a new Machine and wrap it into a `Result.t`
  """
  @spec new(vertices, atom) :: Result.t(error, t)
  def new(vertices, first_step) do
    Result.ok(new!(vertices, first_step))
  catch
    error -> Result.error(error)
  end

  @doc ~S"""
  Run a Machine with a given Input (the first state).

  ## Example

      iex> machine =
      ...>  Circuit.new!(
      ...>    %{
      ...>      A: &{:cont, :B, &1 + 1},
      ...>      B: &{:cont, :C, &1 + 2},
      ...>      C: &{:halt, &1 + 3}
      ...>    },
      ...>    :A
      ...>)
      ...> Circuit.run(0, machine)
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
