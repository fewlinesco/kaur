defmodule Kaur.SecureTest do
  use ExUnit.Case

  test "generate_api_key: generates random keys" do
    api_key1 = Kaur.Secure.generate_api_key
    api_key2 = Kaur.Secure.generate_api_key

    assert api_key1 != api_key2
    assert String.length(api_key1) == String.length(api_key2)
  end
end
