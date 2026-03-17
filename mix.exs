defmodule PixelFont.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pixel_font,
      version: "0.1.0",
      elixir: "~> 1.19",
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix]
      ],
      test_coverage: [tool: ExCoveralls],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  defp elixirc_paths(env)
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:dialyxir, "~> 1.4", only: :dev, runtime: false},
      {:excoveralls, "~> 0.18.5", only: :test},
      {:mox, "~> 1.2", only: :test}
    ]
  end
end
