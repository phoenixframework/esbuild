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
    bin_path = Esbuild.bin_path()

    unless File.exists?(bin_path) do
      Mix.Tasks.Esbuild.Install.run([])
    end

    case System.cmd(bin_path, args, into: IO.stream(), stderr_to_stdout: true) do
      {_, 0} ->
        :ok

      {_, status} ->
        Mix.raise("command `esbuild #{Enum.join(args, " ")}` exited with #{status}")
    end
  end
end
