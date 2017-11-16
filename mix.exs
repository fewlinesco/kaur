defmodule Kaur.Mixfile do
  use Mix.Project

  @project_url "https://github.com/fewlinesco/kaur"

  def project do
    [app: :kaur,
     build_embedded: Mix.env == :prod,
     deps: deps(),
     description: "A bunch of helper functions to ease the development of your applications",
     docs: [main: "README", extras: ["README.md"]],
     elixir: "~> 1.2",
     homepage_url: @project_url,
     name: "Kaur",
     package: package(),
     source_url: @project_url,
     start_permanent: Mix.env == :prod,
     version: "1.0.0"]
  end

  def application do
    []
  end

  defp deps do
    [
      {:credo, "~> 0.8.2", only: [:dev, :test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:earmark, ">= 1.0.3", only: [:docs]},
      {:ex_doc, "~> 0.16.2", only: [:docs]},
      {:excoveralls, "~> 0.7.1", only: [:test]},
      {:inch_ex, "~> 0.5.5", only: [:docs]}
    ]
  end

  defp package do
    [
      licenses: ["MIT"],
      links: %{"GitHub" => @project_url},
      maintainers: ["Fewlines SAS"]
    ]
  end
end
