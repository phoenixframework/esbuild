defmodule Mix.Tasks.Esbuild do
  @moduledoc """
  Invokes esbuild with the given args.

  Usage:

  ```bash
  $ mix esbuild TASK_OPTIONS CONTEXT ARGS
  ```

  Example:

  ```bash
  $ mix esbuild --no-runtime-config default assets/js/app.js --bundle --minify --target=es2016 --outdir=priv/static/assets
  ```

  If esbuild is not installed, it is automatically downloaded.
  Note the arguments given to this task will be appended
  to any configured arguments.
  """

  @shortdoc "Invokes esbuild with the profile and args"

  use Mix.Task

  @impl true
  def run(args) do
    options = [switches: [no_runtime_config: :boolean]]
    {parsed, remaining_args, _errors} = OptionParser.parse_head(args, options)

    if !parsed[:no_runtime_config] && Code.ensure_loaded?(Mix.Tasks.App.Config) do
      Mix.Task.run("app.config")
    end

    install_and_run(remaining_args)
  end

  defp install_and_run([profile | args] = all) do
    case Esbuild.install_and_run(String.to_atom(profile), args) do
      0 -> :ok
      status -> Mix.raise("`mix esbuild #{Enum.join(all, " ")}` exited with #{status}")
    end

    Mix.Task.reenable("esbuild")
  end

  defp install_and_run([]) do
    Mix.raise("`mix esbuild` expects the profile as argument")
  end
end
