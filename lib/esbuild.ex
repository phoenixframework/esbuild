defmodule Esbuild do
  # https://registry.npmjs.org/esbuild/latest
  @latest_version "0.13.4"

  @moduledoc """
  Esbuild is an installer and runner for [esbuild](https://esbuild.github.io).

  ## Profiles

  You can define multiple esbuild profiles. By default, there is a
  profile called `:default` which you can configure its args, current
  directory and environment:

      config :esbuild,
        version: "#{@latest_version}",
        default: [
          args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
          cd: Path.expand("../assets", __DIR__),
          env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
        ]

  ## Esbuild configuration

  There are two global configurations for the esbuild application:

    * `:version` - the expected esbuild version

    * `:path` - the path to find the esbuild executable at. By
      default, it is automatically downloaded and placed inside
      the `_build` directory of your current app

  Overriding the `:path` is not recommended, as we will automatically
  download and manage `esbuild` for you. But in case you can't download
  it (for example, the npm registry is behind a proxy), you may want to
  set the `:path` to a configurable system location.

  For instance, you can install `esbuild` globally with `npm`:

      $ npm install -g esbuild

  On Unix, the executable will be at:

      NPM_ROOT/esbuild/node_modules/esbuild-TARGET/bin/esbuild

  On Windows, it will be at:

      NPM_ROOT/esbuild/node_modules/esbuild-windows-(32|64)/esbuild.exe

  Where `NPM_ROOT` is the result of `npm root -g` and `TARGET` is your system
  target architecture.

  Once you find the location of the executable, you can store it in a
  `MIX_ESBUILD_PATH` environemnt variable, which you can then read in
  your configuration file:

      config :esbuild, path: System.get_env("MIX_ESBUILD_PATH")

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
        :ok
    end

    Supervisor.start_link([], strategy: :one_for_one)
  end

  @doc false
  # Latest known version at the time of publishing.
  def latest_version, do: @latest_version

  @doc """
  Returns the configured esbuild version.
  """
  def configured_version do
    Application.get_env(:esbuild, :version, latest_version())
  end

  @doc """
  Returns the configuration for the given profile.

  Returns nil if the profile does not exist.
  """
  def config_for!(profile) when is_atom(profile) do
    Application.get_env(:esbuild, profile) ||
      raise ArgumentError, """
      unknown esbuild profile. Make sure the profile is defined in your config/config.exs file, such as:

          config :esbuild,
            #{profile}: [
              args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
              cd: Path.expand("../assets", __DIR__),
              env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
            ]
      """
  end

  @doc """
  Returns the path to the executable.

  The executable may not be available if it was not yet installed.
  """
  def bin_path do
    Application.get_env(:esbuild, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), "esbuild")
      else
        Path.expand("_build/esbuild")
      end
  end

  @doc """
  Returns the version of the esbuild executable.

  Returns `{:ok, version_string}` on success or `:error` when the executable
  is not available.
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
  Runs the given command with `args`.

  The given args will be appended to the configured args.
  The task output will be streamed directly to stdio. It
  returns the status of the underlying call.
  """
  def run(profile, extra_args) when is_atom(profile) and is_list(extra_args) do
    config = config_for!(profile)
    args = config[:args] || []

    opts = [
      cd: config[:cd] || File.cwd!(),
      env: config[:env] || %{},
      into: IO.stream(:stdio, :line),
      stderr_to_stdout: true
    ]

    bin_path()
    |> System.cmd(args ++ extra_args, opts)
    |> elem(1)
  end

  @doc """
  Installs, if not available, and then runs `esbuild`.

  Returns the same as `run/2`.
  """
  def install_and_run(profile, args) do
    unless File.exists?(bin_path()) do
      install()
    end

    run(profile, args)
  end

  @doc """
  Installs esbuild with `configured_version/0`.
  """
  def install do
    version = configured_version()
    tmp_dir = Path.join(System.tmp_dir!(), "phx-esbuild")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)

    name = "esbuild-#{target()}"
    url = "https://registry.npmjs.org/#{name}/-/#{name}-#{version}.tgz"
    tar = fetch_body!(url)

    case :erl_tar.extract({:binary, tar}, [:compressed, cwd: to_charlist(tmp_dir)]) do
      :ok -> :ok
      other -> raise "couldn't unpack archive: #{inspect(other)}"
    end

    bin_path = bin_path()
    File.mkdir_p!(Path.dirname(bin_path))

    case :os.type() do
      {:win32, _} ->
        File.cp!(Path.join([tmp_dir, "package", "esbuild.exe"]), bin_path)

      _ ->
        File.cp!(Path.join([tmp_dir, "package", "bin", "esbuild"]), bin_path)
    end
  end

  # Available targets: https://github.com/evanw/esbuild/tree/master/npm
  defp target do
    case :os.type() do
      {:win32, _} ->
        "windows-#{:erlang.system_info(:wordsize) * 8}"

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")

        case arch do
          "amd64" -> "#{osname}-64"
          "x86_64" -> "#{osname}-64"
          "aarch64" -> "#{osname}-arm64"
          # TODO: remove when we require OTP 24
          "arm" when osname == :darwin -> "darwin-arm64"
          "arm" -> "#{osname}-arm"
          _ -> raise "could not download esbuild for architecture: #{arch_str}"
        end
    end
  end

  defp fetch_body!(url) do
    url = String.to_charlist(url)
    Logger.debug("Downloading esbuild from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
      Logger.debug("Using HTTP_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
    end

    if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
      Logger.debug("Using HTTPS_PROXY: #{proxy}")
      %{host: host, port: port} = URI.parse(proxy)
      :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = CAStore.file_path() |> String.to_charlist()

    http_options = [
      ssl: [
        verify: :verify_peer,
        cacertfile: cacertfile,
        depth: 2,
        customize_hostname_check: [
          match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
        ]
      ]
    ]

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise "couldn't fetch #{url}: #{inspect(other)}"
    end
  end
end
