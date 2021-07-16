defmodule Esbuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :esbuild,
      version: "0.1.0",
      elixir: "~> 1.7",
      deps: deps(),
      xref: xref()
    ]
  end

  def application do
    [
      # inets/ssl may be used by Mix tasks but we should not impose them.
      extra_applications: [:logger],
      mod: {Esbuild, []}
    ]
  end

  defp deps do
    [
      {:castore, ">= 0.0.0"}
    ]
  end

  defp xref do
    [
      exclude: [:httpc, :public_key]
    ]
  end
end
