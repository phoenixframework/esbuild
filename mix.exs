defmodule Esbuild.MixProject do
  use Mix.Project

  def project do
    [
      app: :esbuild,
      version: "0.1.0",
      elixir: "~> 1.9",
      deps: deps(),
      xref: xref(),
      aliases: [test: ["esbuild.install --if-missing", "test"]]
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
