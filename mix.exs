defmodule Esbuild.MixProject do
  use Mix.Project

  @version "0.8.1"
  @source_url "https://github.com/phoenixframework/esbuild"

  def project do
    [
      app: :esbuild,
      version: @version,
      elixir: "~> 1.11",
      deps: deps(),
      description: "Mix tasks for installing and invoking esbuild",
      package: [
        links: %{
          "GitHub" => @source_url,
          "esbuild" => "https://esbuild.github.io"
        },
        licenses: ["MIT"]
      ],
      docs: [
        main: "Esbuild",
        source_url: @source_url,
        source_ref: "v#{@version}",
        extras: ["CHANGELOG.md"]
      ],
      aliases: [test: ["esbuild.install --if-missing", "test"]]
    ]
  end

  def application do
    [
      extra_applications: [:logger, inets: :optional, ssl: :optional],
      mod: {Esbuild, []},
      env: [default: []]
    ]
  end

  defp deps do
    [
      {:castore, ">= 0.0.0"},
      {:jason, "~> 1.4"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
