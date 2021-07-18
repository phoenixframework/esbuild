defmodule Mix.Tasks.Esbuild do
  @moduledoc """
  Invokes esbuild with the given args.

  Usage:

  ```bash
  $ mix esbuild CONTEXT ARGS
  ```

  Example:

  ```bash
  $ mix esbuild default assets/js/app.js --bundle --minify --target=es2016 --outdir=priv/static/assets
  ```

  If esbuild is not installed, it is automatically downloaded.
  Note the arguments given to this task will be appended
  to any configured arguments.
  """

  @shortdoc "Invokes esbuild with the context and args"

  use Mix.Task

  @impl true
  def run([context | args] = all) do
    Mix.Task.run("app.config")

    case Esbuild.install_and_run(String.to_atom(context), args) do
      0 -> :ok
      status -> Mix.raise("`mix esbuild #{Enum.join(all, " ")}` exited with #{status}")
    end
  end

  def run([]) do
    Mix.raise("`mix esbuild` expects the context as argument")
  end
end
