defmodule Kaur.Environment do
  @moduledoc """
  **This module is deprecated and will no longer be maintained**

  Utilities for working with configuration allowing environment variables.

  * `{:system, something}`: will load the environment variable stored in `something`
  * `value`: will return the value
  """

  alias Kaur.Result

  @doc ~S"""
  Reads the value or environment variable for the `key` in `application`'s environment.

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
  @deprecated "Kaur.Environment is deprecated and will no longer be maintained"
  @spec read(:atom, :atom) :: Result.t(any, any)
  def read(application, key) do
    application
    |> Application.get_env(key)
    |> Result.from_value()
    |> Result.and_then(&load_environment_variable/1)
  end

  @doc ~S"""
  Reads the value or environment variable for the `key` in `application`'s environment.

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
  @deprecated "Kaur.Environment is deprecated and will no longer be maintained"
  @spec read(:atom, :atom, [:atom]) :: Result.t(any, any)
  def read(application, key, sub_keys) do
    application
    |> Application.get_env(key)
    |> Result.from_value()
    |> Result.and_then(&deep_get(&1, sub_keys))
    |> Result.and_then(&load_environment_variable/1)
  end

  defp load_environment_variable({:system, environment_variable}) do
    environment_variable
    |> System.get_env()
    |> Result.from_value()
  end

  defp load_environment_variable(value) do
    Result.from_value(value)
  end

  defp deep_get(values, sub_keys) do
    values
    |> get_in(sub_keys)
    |> Result.from_value()
  end
end
