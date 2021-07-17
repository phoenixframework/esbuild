defmodule Mix.Tasks.Esbuild do
  @moduledoc """
  Invokes esbuild with the given args.

      mix esbuild assets/js/app.js --bundle --minify --target=es2016 --outfile=priv/static/assets/app.js

  If it is not installed, one is automatically picked.
  """

  @shortdoc "Invokes esbuild with the given args"

  use Mix.Task

  @impl true
  def run(args) do
    Mix.Task.run("app.config")

    case Esbuild.install_and_run(args) do
      0 -> :ok
      status -> Mix.raise("`mix esbuild #{Enum.join(args, " ")}` exited with #{status}")
    end
  end
end
