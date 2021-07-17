defmodule Mix.Tasks.Esbuild do
  @moduledoc """
  Invokes esbuild with the given args.

      mix esbuild assets/js/app.js --bundle --minify --target=es2016 --outdir=priv/static/assets

  If it is not installed, one is automatically installed.
  Note the arguments given to this task will be appended
  to any configured arguments.
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
