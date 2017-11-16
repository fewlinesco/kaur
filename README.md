[![Hex pm](https://img.shields.io/hexpm/v/kaur.svg)](https://hex.pm/packages/kaur)
[![Build
Status](https://travis-ci.org/fewlinesco/kaur.svg?branch=master)](https://travis-ci.org/fewlinesco/kaur)
[![Inline docs](http://inch-ci.org/github/fewlinesco/kaur.svg)](http://inch-ci.org/github/fewlinesco/kaur)

# Kaur

> Pronounced |kɔː|

A bunch of helper functions to ease the development of your applications.

## Installation

```elixir
def deps do
  [{:kaur, "~> 1.0.0"}]
end
```

## Usage

### `:ok`, `:error` tuples A.K.A `Result` tuples

`{:ok, value}` and `{:error, reason}` is a common pattern in Erlang and Elixir. The `Kaur.Result` module adds functions
to help deal with these values without getting out of your pipeline.

You can have a look at [the documentation](https://hexdocs.pm/kaur) to know what's available or you can take a look at
[how we use it in Kaur itself](https://github.com/fewlinesco/kaur/blob/master/lib/kaur/environment.ex#L61..L65).

Just below you will find a small example of how your code could look like using `Kaur.Result`. In this example we try
to determine if a person can rent a car. People can rent a car if they are between 21 and 99 year old and have a bonus
greater than 0.8.

#### Example without Kaur

```elixir
defmodule Person do
  defstruct [:name, :age, :bonus]
end

defmodule MyModule do
  def rent_a_car(person = %Person{}) do
    with {:ok, person1} <- validate_age(person),
         {:ok, person2} <- validate_bonus(person1)
    do
      {:ok, display_driving_message(person2)}
    else
      {:error, reason} ->
        {:error, handle_error(person, reason)}
    end
  end

  defp display_driving_message(person) do
    "Welcome #{person.name}, you can rent a car"
  end

  defp handle_error(person, {:bonus, expected_bonus}) do
    "Sorry #{person.name}, but you need a bonus of #{expected_bonus} but have only #{person.bonus}."
  end
  defp handle_error(person, {:license_type, expected_license}) do
    "Sorry #{person.name}, but you need a #{expected_license} license but have a #{person.license_type} license."
  end
  defp handle_error(person, {:too_old, maximum_age}) do
    "Sorry #{person.name}, but you need to be younger than #{maximum_age}"
  end
  defp handle_error(person, {:too_young, minimum_age}) do
    "Sorry #{person.name}, but you need to be older than #{minimum_age}"
  end

  defp validate_age(%{age: age}) when age > 99, do: {:error, {:too_old, 99}}
  defp validate_age(%{age: age}) when age < 21, do: {:error, {:too_young, 21}}
  defp validate_age(person), do: {:ok, person}

  defp validate_bonus(person = %{bonus: bonus}) when bonus > 0.8, do: {:ok, person}
  defp validate_bonus(_person), do: {:error, {:bonus, 0.8}}
end
```

#### Example using Kaur

```elixir
defmodule MyModule do
  alias Kaur.Result

  def rent_a_car(person = %Person{}) do
    person
    |> validate_age()
    |> Result.and_then(&validate_bonus/1)
    |> Result.map(&display_driving_message/1)
    |> Result.map_error(&handle_error(person, &1))
  end

  # ... Same business logic as before
end
```

Execution

```
iex> MyModule.rent_a_car %Person{name: "Jane", age: 42, bonus: 0.9}
{:ok, "Welcome Jane, you can rent a car"}

iex> MyModule.rent_a_car %Person{name: "John", age: 42, bonus: 0.5}
{:error, Sorry John, but you need a bonus of 0.8 but have only 0.5."}

iex> MyModule.rent_a_car %Person{name: "Robert", age: 11, bonus: 0.9}
{:error, "Sorry Robert, but you need to be older than 21"}

iex> MyModule.rent_a_car %Person{name: "Mary", age: 122, bonus: 0.8}
{:error, "Sorry Mary, but you need to be younger than 99"}
```

### Security

A small module which can generate API keys:

```
iex>  Kaur.Secure.generate_api_key
"UtiE9qs-7FbJs8OIt5nCiw=="

iex> Kaur.Secure.generate_api_key
"BTxaJNrA_QsAhWSLKOMj8A==
```

### Environment Variables

We love environment variables but, unfortunately, Elixir configuration doesn't play well with them. If we use
`System.get_env` in `config/*.exs` files, they will be evaluated at compile time.

We would really want to have our configuration based on environment variables. A common pattern is to use
`{:system, "ENVIRONMENT_VARIABLE"}` wherever we need a value to be fetched at runtime. That's common but, unfortunately,
that's not built-in so we have to handle this behaviour ourselves.

`Kaur.Environment` abstracts how we read application configuration so it can automatically handle the loading of
environment variables when it's needed.

```
# config/config.exs
config :my_app, :my_key, {:system, "MY_KEY"}
config :my_app, :my_key2, "MY STATIC VALUE"

iex> Kaur.Environment.read(:my_app, :my_key)
{:ok, "VALUE DYNAMICALLY LOADED"}

iex> Kaur.Environment.read(:my_app, :my_key2)
{:ok, "MY STATIC VALUE"}

iex> Kaur.Environment.read(:my_app, :something_else)
{:error, :no_value}
```

## Code of Conduct

By participating in this project, you agree to abide by its [CODE OF CONDUCT](CODE_OF_CONDUCT.md).

## Contributing

You can see the specific [CONTRIBUTING](CONTRIBUTING.md) guide.

## License

Kaur is released under [The MIT License (MIT)](https://opensource.org/licenses/MIT).
