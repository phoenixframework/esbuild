defmodule Mix.Tasks.Esbuild.Install do
  @moduledoc """
  Installs esbuild under `_build`.

  ```bash
  $ mix esbuild.install
  $ mix esbuild.install --if-missing
  ```

  By default, it installs #{Esbuild.latest_version()} but you
  can configure it in your config files, such as:

      config :esbuild, :version, "#{Esbuild.latest_version()}"

  You can pass the `--if-missing` flag to only install it if
  one does not yet exist at the given version.
  """

  @shortdoc "Installs esbuild under _build"
  use Mix.Task

  @impl true
  def run(args) do
    case OptionParser.parse_head!(args, strict: [if_missing: :boolean]) do
      {opts, []} ->
        if opts[:if_missing] && latest_version?() do
          :ok
        else
          if Code.ensure_loaded?(Mix.Tasks.App.Config) do
            Mix.Task.run("app.config")
          end

          Esbuild.install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to esbuild.install, expected one of:

            mix esbuild.install
            mix esbuild.install --if-missing
        """)
    end
  end

  defp latest_version?() do
    version = Esbuild.configured_version()
    match?({:ok, ^version}, Esbuild.bin_version())
  end
end
