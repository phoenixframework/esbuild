defmodule Esbuild do
  @moduledoc """
  Esbuild is a installer for [esbuild](https://github.com/evanw/esbuild/).

  See the available Mix tasks.
  """

  use Application
  require Logger

  @doc false
  def start(_, _) do
    unless Application.get_env(:esbuild, :version) do
      Logger.warn("""
      esbuild version is not configured. Please set it in your config files:

          config :esbuild, :version, "#{latest_version()}"
      """)
    end

    configured_version = configured_version()

    case bin_version() do
      {:ok, ^configured_version} ->
        :ok

      {:ok, version} ->
        Logger.warn("""
        Outdated esbuild version. Expected #{configured_version}, got #{version}. \
        Please run `mix esbuild.install` or update the version in your config files.\
        """)

      :error ->
        Logger.warn("""
        esbuild is missing. Run `mix esbuild.install` to download it.\
        """)
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    Path.join(Path.dirname(Mix.Project.build_path()), "esbuild")
  end

  @doc """
  Returns the version of the esbuild executable.

  Returns `{:ok, version_string}` or `:error` if
  the executable is available or the version could
  not be fetched.
  """
  def bin_version do
    path = bin_path()

    with true <- File.exists?(path),
         {result, 0} <- System.cmd(path, ["--version"]) do
      {:ok, String.trim(result)}
    else
      _ -> :error
    end
  end

  @doc """
  Returns the configured esbuild version.
  """
  def configured_version do
    Application.get_env(:esbuild, :version, latest_version())
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version do
    "0.12.15"
  end
end
