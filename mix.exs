defmodule StoutPorter2.MixProject do
  use Mix.Project

  def project do
    [
      app: :stout_porter2,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      source_url: "https://github.com/stout_porter2XXXXTODO"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:benchfella, "~> 0.3.0", only: :dev},
      {:earmark, "~> 1.2", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp description() do
    "Efficient implementation of the English Porter2 stemming algorithm."
  end

  defp package() do
    [
      name: "stout_porter2",
      licenses: ["AGPL-3.0"],
      links: %{"GitHub" => "https://github.com/XXXXXXXTODOXXXXX"}
    ]
  end
end
