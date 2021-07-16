defmodule Mix.Tasks.Esbuild.Install do
  @moduledoc """
  Installs esbuild under _build.

      mix escript.install
      mix escript.install --if-missing

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
          install()
        end

      {_, _} ->
        Mix.raise("""
        Invalid arguments to escript.install, expected one of:

            mix escript.install
            mix escript.install --if-missing
        """)
    end
  end

  defp install do
    Mix.Task.run("app.config")

    version = Esbuild.configured_version()
    tmp_dir = Path.join(System.tmp_dir!(), "phx-esbuild")
    File.rm_rf!(tmp_dir)
    File.mkdir_p!(tmp_dir)

    name = "esbuild-#{target()}"
    url = "https://registry.npmjs.org/#{name}/-/#{name}-#{version}.tgz"
    tar = fetch_body!(url)

    case :erl_tar.extract({:binary, tar}, [:compressed, cwd: tmp_dir]) do
      :ok -> :ok
      other -> raise "couldn't unpack archive: #{inspect(other)}"
    end

    bin_path = Esbuild.bin_path()
    File.rename!(Path.join([tmp_dir, "package", "bin", "esbuild"]), bin_path)
    Mix.shell().info("Installed esbuild #{version}")
  end

  # Available targets: https://github.com/evanw/esbuild/tree/master/npm
  defp target() do
    case :erlang.system_info(:system_architecture) do
      # darwin

      'x86_64-apple-darwin' ++ _ ->
        "darwin-64"

      'aarch64-apple-darwin' ++ _ ->
        "darwin-arm64"

      # linux

      'x86_64-pc-linux' ++ _ ->
        "linux-64"

      'aarch64-pc-linux' ++ _ ->
        "linux-arm64"

      # windows

      'win32' ->
        "windows-#{:erlang.system_info(:wordsize) * 8}"

      other ->
        Mix.raise("Could not download esbuild for architecture: #{other}")
    end
  end

  defp fetch_body!(url) do
    url = String.to_charlist(url)
    Mix.shell().info("Downloading esbuild from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

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
