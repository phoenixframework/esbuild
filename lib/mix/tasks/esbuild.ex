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

  @shortdoc "Invokes esbuild with the profile and args"

  use Mix.Task

  @impl true
  def run([profile | args] = all) do
    if Code.ensure_loaded?(Mix.Tasks.App.Config) do
      Mix.Task.run("app.config")
    end

    case Esbuild.install_and_run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix esbuild #{Enum.join(all, " ")}` exited with #{status}")
    end

    Mix.Task.reenable("esbuild")
  end

  def run([]) do
    Mix.raise("`mix esbuild` expects the profile as argument")
  end
end
