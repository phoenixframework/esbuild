defmodule NpmRegistry do
  require Logger

  @base_url "https://registry.npmjs.org"
  @public_key_pem File.read!("npm-registry.pem")
  @public_key_id "SHA256:jl3bwswu80PjjokCgh0o2w5c2U4LhQAE57gj9cz1kzA"
  @public_key_ec_curve :prime256v1

  def fetch_package!(name, version) do
    %{
      "_id" => id,
      "dist" => %{
        "integrity" => integrity,
        "signatures" => [
          %{
            "keyid" => @public_key_id,
            "sig" => signature
          }
        ],
        "tarball" => tarball
      }
    } =
      fetch_file!("#{@base_url}/#{name}/#{version}")
      |> Jason.decode!()

    verify_signature!("#{id}:#{integrity}", signature)
    tar = fetch_file!(tarball)

    [hash_alg, checksum] =
      integrity
      |> String.split("-")

    verify_integrity!(tar, hash_alg, Base.decode64!(checksum))

    tar
  end

  defp fetch_file!(url) do
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
      ] |> maybe_add_proxy_auth(scheme),
      [body_format: :binary]
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
    :crypto.verify(
      :ecdsa,
      :sha256,
      message,
      Base.decode64!(signature),
      [public_key(), @public_key_ec_curve]
    ) || raise "invalid signature"
  end

  defp verify_integrity!(binary, hash_alg, checksum) do
    hash_alg
    |> hash_alg_to_erlang()
    |> :crypto.hash(binary)
    |>:crypto.hash_equals(checksum) || raise "invalid checksum"
  end

  defp public_key do
    [entry] = :public_key.pem_decode(@public_key_pem)
    {{:ECPoint, ec_point}, _} = :public_key.pem_entry_decode(entry)

    ec_point
  end

  defp hash_alg_to_erlang("sha512"), do: :sha512
end
