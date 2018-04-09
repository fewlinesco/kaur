defmodule Kaur.Circuit.UserWorkflow do
  alias Kaur.Circuit
  alias Kaur.Result

  @doc """
  Initialize the database
  """
  def init do
    :ets.new(:users, [:set, :named_table])
    :ets.insert(:users, {{:name, "xvw"}, {:email, "xvw@gmeil.com"}})
    :ok
  end

  @doc """
  Run the worflow
  """
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
    IO.puts("Hello #{name}")
    {:halt, Result.ok(user)}
  end

  defp user_exists({{_, {:email, email}} = user, email}) do
    {:cont, :Connection, user}
  end

  defp user_exists(_) do
    {:halt, Result.error(:invalid_email)}
  end
end
