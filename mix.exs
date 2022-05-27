defmodule Esbuild.MixProject do
  use Mix.Project

  @version "0.5.0"
  @source_url "https://github.com/phoenixframework/esbuild"

  def project do
    [
      app: :esbuild,
      version: @version,
      elixir: "~> 1.10",
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
      xref: [
        exclude: [:httpc, :public_key]
      ],
      aliases: [test: ["esbuild.install --if-missing", "test"]]
    ]
  end

  def application do
    [
      # inets/ssl may be used by Mix tasks but we should not impose them.
      extra_applications: [:logger],
      mod: {Esbuild, []},
      env: [default: []]
    ]
  end

  defp deps do
    [
      {:castore, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
