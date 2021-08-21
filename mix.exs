defmodule PixelFont.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pixel_font,
      version: "0.1.0",
      elixir: "~> 1.11",
      deps: deps(),
      dialyzer: [
        plt_add_apps: [:mix]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  defp elixirc_paths(env)
  defp elixirc_paths(:test), do: ["test/support", "lib"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
