defmodule Esbuild do
  # https://registry.npmjs.org/esbuild/latest
  @latest_version "0.16.4"

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

    * `:cacerts_path` - the directory to find certificates for
      https connections

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

      NPM_ROOT/esbuild/node_modules/@esbuild/TARGET/bin/esbuild

  On Windows, it will be at:

      NPM_ROOT/esbuild/node_modules/@esbuild/win32-x(32|64)/esbuild.exe

  Where `NPM_ROOT` is the result of `npm root -g` and `TARGET` is your system
  target architecture.

  Once you find the location of the executable, you can store it in a
  `MIX_ESBUILD_PATH` environment variable, which you can then read in
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
    name = "esbuild-#{target()}"

    Application.get_env(:esbuild, :path) ||
      if Code.ensure_loaded?(Mix.Project) do
        Path.join(Path.dirname(Mix.Project.build_path()), name)
      else
        Path.expand("_build/#{name}")
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

    if args == [] and extra_args == [] do
      raise "no arguments passed to esbuild"
    end

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
    tmp_opts = if System.get_env("MIX_XDG"), do: %{os: :linux}, else: %{}

    tmp_dir =
      freshdir_p(:filename.basedir(:user_cache, "phx-esbuild", tmp_opts)) ||
        freshdir_p(Path.join(System.tmp_dir!(), "phx-esbuild")) ||
        raise "could not install esbuild. Set MIX_XGD=1 and then set XDG_CACHE_HOME to the path you want to use as cache"

    url =
      if Version.compare(version, "0.16.0") in [:eq, :gt] do
        target = target()
        "https://registry.npmjs.org/@esbuild/#{target}/-/#{target}-#{version}.tgz"
      else
        # TODO: Remove else clause or raise if esbuild < 0.16.0 don't need to be supported anymore
        name = "esbuild-#{target_legacy()}"
        "https://registry.npmjs.org/#{name}/-/#{name}-#{version}.tgz"
      end

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

  defp freshdir_p(path) do
    with {:ok, _} <- File.rm_rf(path),
         :ok <- File.mkdir_p(path) do
      path
    else
      _ -> nil
    end
  end

  # Available targets: https://github.com/evanw/esbuild/tree/main/npm/@esbuild
  defp target do
    case :os.type() do
      # Assuming it's an x86 CPU
      {:win32, _} ->
        wordsize = :erlang.system_info(:wordsize)

        if wordsize == 8 do
          "win32-x64"
        else
          "win32-ia32"
        end

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")

        case arch do
          "amd64" -> "#{osname}-x64"
          "x86_64" -> "#{osname}-x64"
          "i686" -> "#{osname}-ia32"
          "i386" -> "#{osname}-ia32"
          "aarch64" -> "#{osname}-arm64"
          # TODO: remove when we require OTP 24
          "arm" when osname == :darwin -> "darwin-arm64"
          "arm" -> "#{osname}-arm"
          "armv7" <> _ -> "#{osname}-arm"
          _ -> raise "esbuild is not available for architecture: #{arch_str}"
        end
    end
  end

  # TODO: Remove if esbuild < 0.16.0 don't need to be supported anymore
  # Available targets: https://github.com/evanw/esbuild/tree/v0.15.18/npm
  defp target_legacy do
    case :os.type() do
      {:win32, _} ->
        "windows-#{:erlang.system_info(:wordsize) * 8}"

      {:unix, osname} ->
        arch_str = :erlang.system_info(:system_architecture)
        [arch | _] = arch_str |> List.to_string() |> String.split("-")

        case arch do
          "amd64" -> "#{osname}-64"
          "x86_64" -> "#{osname}-64"
          "i686" -> "#{osname}-32"
          "i386" -> "#{osname}-32"
          "aarch64" -> "#{osname}-arm64"
          # TODO: remove when we require OTP 24
          "arm" when osname == :darwin -> "darwin-arm64"
          "arm" -> "#{osname}-arm"
          "armv7" <> _ -> "#{osname}-arm"
          _ -> raise "esbuild is not available for architecture: #{arch_str}"
        end
    end
  end

  defp fetch_body!(url) do
    scheme = URI.parse(url).scheme
    url = String.to_charlist(url)
    Logger.debug("Downloading esbuild from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = proxy_for_scheme(scheme) do
      %{host: host, port: port} = URI.parse(proxy)
      Logger.debug("Using #{String.upcase(scheme)}_PROXY: #{proxy}")
      set_option = if "https" == scheme, do: :https_proxy, else: :proxy
      :httpc.set_options([{set_option, {{String.to_charlist(host), port}, []}}])
    end

    # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
    cacertfile = cacertfile() |> String.to_charlist()

    http_options =
      [
        ssl: [
          verify: :verify_peer,
          cacertfile: cacertfile,
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
      |> maybe_add_proxy_auth(scheme)

    options = [body_format: :binary]

    case :httpc.request(:get, {url, []}, http_options, options) do
      {:ok, {{_, 200, _}, _headers, body}} ->
        body

      other ->
        raise """
        couldn't fetch #{url}: #{inspect(other)}

        You may also install the "esbuild" executable manually, \
        see the docs: https://hexdocs.pm/esbuild
        """
    end
  end

  defp proxy_for_scheme("http") do
    System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
  end

  defp proxy_for_scheme("https") do
    System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
  end

  defp maybe_add_proxy_auth(http_options, scheme) do
    case proxy_auth(scheme) do
      nil -> http_options
      auth -> [{:proxy_auth, auth} | http_options]
    end
  end

  defp proxy_auth(scheme) do
    with proxy when is_binary(proxy) <- proxy_for_scheme(scheme),
         %{userinfo: userinfo} when is_binary(userinfo) <- URI.parse(proxy),
         [username, password] <- String.split(userinfo, ":") do
      {String.to_charlist(username), String.to_charlist(password)}
    else
      _ -> nil
    end
  end

  defp cacertfile() do
    Application.get_env(:esbuild, :cacerts_path) || CAStore.file_path()
  end
end
