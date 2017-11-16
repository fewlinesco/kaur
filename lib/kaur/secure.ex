defmodule Kaur.Secure do
  @moduledoc """
  Utilities to generate secure API Keys
  """

  @doc """
  Generate a formatted String of length 24, using base 64 encoding.

  ## Examples

    iex> Kaur.Secure.generate_api_key
    "tEhdf77Pr8BDjRc9JMKGzQ=="
  """
  @spec generate_api_key :: String.t
  def generate_api_key do
    Base.url_encode64(random_bytes())
  end

  defp random_bytes do
    :crypto.strong_rand_bytes(16)
  end
end
