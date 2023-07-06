defmodule NpmRegistry do
  require Logger

  @base_url "https://registry.npmjs.org"

  def fetch_file!(path) do
    url = @base_url <> path
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
end
