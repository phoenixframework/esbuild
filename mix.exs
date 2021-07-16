defmodule Esbuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :esbuild,
      version: "0.1.0",
      elixir: "~> 1.7",
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger, :inets, :ssl],
      mod: {Esbuild, []}
    ]
  end

  defp deps do
    [
      {:castore, ">= 0.0.0"}
    ]
  end
end
