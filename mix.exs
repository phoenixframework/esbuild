defmodule Esbuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :esbuild,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
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
      {:castore, "~> 0.1.0"}
    ]
  end
end
