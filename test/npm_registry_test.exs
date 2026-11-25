defmodule Esbuild.NpmRegistryTest do
  # Changes the OS environment, so it cannot run concurrently with other tests.
  use ExUnit.Case, async: false

  @vars ["HTTP_PROXY", "http_proxy", "HTTPS_PROXY", "https_proxy"]

  setup do
    previous = Map.new(@vars, &{&1, System.get_env(&1)})
    Enum.each(@vars, &System.delete_env/1)

    on_exit(fn ->
      Enum.each(previous, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end)
  end

  test "proxy_for_scheme/1 returns the configured proxy" do
    System.put_env("HTTP_PROXY", "http://proxy.local:3128")
    System.put_env("https_proxy", "http://secure.local:3128")

    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == "http://proxy.local:3128"
    assert Esbuild.NpmRegistry.proxy_for_scheme("https") == "http://secure.local:3128"
  end

  test "proxy_for_scheme/1 handles blank variables as if they were not set" do
    System.put_env("HTTP_PROXY", "")
    System.put_env("HTTPS_PROXY", "  ")

    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == nil
    assert Esbuild.NpmRegistry.proxy_for_scheme("https") == nil
  end

  test "proxy_for_scheme/1 falls back to the lowercase variable when the uppercase one is blank" do
    System.put_env("HTTP_PROXY", "")
    System.put_env("http_proxy", "http://proxy.local:3128")

    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == "http://proxy.local:3128"
  end
end
