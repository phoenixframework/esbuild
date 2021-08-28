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

  You can pass the `--if-missing` flag to only install if
  one does not yet exist or if the version configured is newer.
  """

  @shortdoc "Installs esbuild under _build"
  use Mix.Task

  @impl true
  def run(args) do
    case OptionParser.parse_head!(args, strict: [if_missing: :boolean]) do
      {opts, []} ->
        if opts[:if_missing] && File.exists?(Esbuild.bin_path()) &&
             latest_configured_version_installed?() do
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

  defp latest_configured_version_installed?() do
    {:ok, version_installed} = Esbuild.bin_version()
    # Fallback to version_installed if no config found
    version_to_compare = Application.get_env(:esbuild, :version, version_installed)

    version_installed === version_to_compare
  end
end
