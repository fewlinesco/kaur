defmodule Kaur.Environment do
  @moduledoc """
  Utilities for working with configuration allowing environment variables.

  * `{:system, something}`: will load the environment variable stored in `something`
  * `value`: will returns the value
  """

  @doc """
  Read the value or environment variable for the `key` in `application`'s environment

  ### Examples

  If we imagine a config file like:

      # config/config.exs
      config :my_app, :my_key, {:system, "MY_KEY"}
      config :my_app, :my_key2, "MY_VALUE"

      iex> Kaur.Environment.read(:my_app, :my_key)
      {:ok, "VALUE STORE IN MY_KEY"}

      iex> Kaur.Environment.read(:my_app, :my_key2)
      {:ok, "MY VALUE"}

      iex> Kaur.Environment.read(:my_app, :something_else)
      {:error, :no_value}
  """
  @spec read(:atom, :atom) :: Kaur.ResultTuple.result_tuple
  def read(application, key) do
    application
    |> Application.get_env(key)
    |> Kaur.ResultTuple.from_value
    |> Kaur.ResultTuple.and_then(&load_environment_variable/1)
  end

  @doc """
  Read the value or environment variable for the `key` in `application`'s environment

  ### Examples

  If we imagine a config file like:

      # config/config.exs
      config :my_app, :my_key, secret: {:system, "MY_KEY"}
      config :my_app, :my_key2, secret: "MY_VALUE"

      iex> Kaur.Environment.read(:my_app, :my_key, [:secret])
      {:ok, "VALUE STORE IN MY_KEY"}

      iex> Kaur.Environment.read(:my_app, :my_key2, [:secret])
      {:ok, "MY VALUE"}

      iex> Kaur.Environment.read(:my_app, :something_else)
      {:error, :no_value}
  """
  @spec read(:atom, :atom, [:atom]) :: Kaur.ResultTuple.result_tuple
  def read(application, key, sub_keys) do
    application
    |> Application.get_env(key)
    |> Kaur.ResultTuple.from_value
    |> Kaur.ResultTuple.and_then(&deep_get(&1, sub_keys))
    |> Kaur.ResultTuple.and_then(&load_environment_variable/1)
  end

  defp load_environment_variable({:system, environment_variable}) do
    environment_variable
    |> System.get_env
    |> Kaur.ResultTuple.from_value
  end
  defp load_environment_variable(value) do
    Kaur.ResultTuple.from_value(value)
  end

  defp deep_get(values, sub_keys) do
    values
    |> get_in(sub_keys)
    |> Kaur.ResultTuple.from_value
  end
end
