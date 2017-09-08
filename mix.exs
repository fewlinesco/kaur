defmodule Kaur.Mixfile do
  use Mix.Project

  def project do
    [app: :kaur,
     version: "0.1.0",
     elixir: "~> 1.5",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: "A bunch of helper functions we use in different projects.",
     deps: deps()]
  end

  def application do
    []
  end

  defp deps do
    [{:dialyxir, "~> 0.5", only: [:dev, :test], runtime: false},
     {:ex_doc, "~> 0.16", only: [:dev], runtime: false}]
  end
end
