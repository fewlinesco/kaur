defmodule Kaur.Secure do
  @moduledoc """
  **This module is deprecated and will be no longer maintained**

  Utilities to generate secure API Keys.
  """

  @doc ~S"""
  Generates a formatted String of length 24, using base 64 encoding.

  ## Examples

    iex> Kaur.Secure.generate_api_key()
    "tEhdf77Pr8BDjRc9JMKGzQ=="
  """
  @deprecated "Kaur.Secure is deprecated and will be no longer maintained"
  @spec generate_api_key :: String.t()
  def generate_api_key do
    Base.url_encode64(random_bytes())
  end

  defp random_bytes do
    :crypto.strong_rand_bytes(16)
  end
end
