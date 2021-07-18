defmodule Mix.Tasks.Esbuild.Install do
  @moduledoc """
  Installs esbuild under `_build`.

  ```bash
  $ mix escript.install
  $ mix escript.install --if-missing
  ```

  By default, it installs #{Esbuild.latest_version()} but you
  can configure it in your config files, such as:

      config :esbuild, :version, "#{Esbuild.latest_version()}"

  You can pass the `--if-missing` flag to only install it if
  one does not yet exist.
  """

  @shortdoc "Installs esbuild under _build"
  use Mix.Task

  @impl true
  def run(args) do
    case OptionParser.parse_head!(args, strict: [if_missing: :boolean]) do
      {opts, []} ->
        if opts[:if_missing] && File.exists?(Esbuild.bin_path()) do
          :ok
        else
          Mix.Task.run("app.config")
          Esbuild.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to escript.install, expected one of:

            mix escript.install
            mix escript.install --if-missing
        """)
    end
  end
end
