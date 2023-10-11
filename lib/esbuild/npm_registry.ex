defmodule Esbuild.NpmRegistry do
  @moduledoc false
  require Logger

  # source: https://registry.npmjs.org/-/npm/v1/keys
  @public_key_pem """
  -----BEGIN PUBLIC KEY-----
  MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE1Olb3zMAFFxXKHiIkQO5cJ3Yhl5i
  6UPp+IhuteBJbuHcA5UogKo0EWtlWwW6KSaKoTNEYL7JlCQiVnkhBktUgg==
  -----END PUBLIC KEY-----
  """

  @base_url "https://registry.npmjs.org"
  @public_key_id "SHA256:jl3bwswu80PjjokCgh0o2w5c2U4LhQAE57gj9cz1kzA"

  def fetch_package!(name, version) do
    url = "#{@base_url}/#{name}/#{version}"
    scheme = URI.parse(url).scheme
    Logger.debug("Downloading esbuild from #{url}")

    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    if proxy = proxy_for_scheme(scheme) do
      %{host: host, port: port} = URI.parse(proxy)
      Logger.debug("Using #{String.upcase(scheme)}_PROXY: #{proxy}")
      set_option = if "https" == scheme, do: :https_proxy, else: :proxy
      :httpc.set_options([{set_option, {{String.to_charlist(host), port}, []}}])
    end

    %{
      "_id" => id,
      "dist" => %{
        "integrity" => integrity,
        "signatures" => signatures,
        "tarball" => tarball
      }
    } =
      fetch_file!(url)
      |> Jason.decode!()

    %{"sig" => signature} =
      signatures
      |> Enum.find(fn %{"keyid" => keyid} -> keyid == @public_key_id end) ||
        raise "missing signature"

    verify_signature!("#{id}:#{integrity}", signature)
    tar = fetch_file!(tarball)

    [hash_alg, checksum] =
      integrity
      |> String.split("-")

    verify_integrity!(tar, hash_alg, Base.decode64!(checksum))

    tar
  end

  defp fetch_file!(url) do
    case do_fetch(url) do
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

  defp do_fetch(url) do
    scheme = URI.parse(url).scheme
    url = String.to_charlist(url)

    :httpc.request(
      :get,
      {url, []},
      [
        ssl: [
          verify: :verify_peer,
          # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
          cacertfile: cacertfile() |> String.to_charlist(),
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
      |> maybe_add_proxy_auth(scheme),
      body_format: :binary
    )
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

  defp verify_signature!(message, signature) do
    :public_key.verify(
      message,
      :sha256,
      Base.decode64!(signature),
      public_key()
    ) or raise "invalid signature"
  end

  defp verify_integrity!(binary, hash_alg, checksum) do
    binary_checksum =
      hash_alg
      |> hash_alg_to_erlang()
      |> :crypto.hash(binary)

    binary_checksum == checksum or raise "invalid checksum"
  end

  defp public_key do
    [entry] = :public_key.pem_decode(@public_key_pem)
    :public_key.pem_entry_decode(entry)
  end

  defp hash_alg_to_erlang("sha512"), do: :sha512
end
