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
      ]
    ]
  end

  defp deps do
    [
      {:dialyxir, "~> 1.0", only: :dev, runtime: :false}
    ]
  end
end
