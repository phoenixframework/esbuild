defmodule Esbuild.NpmRegistryTest do
  # Changes the OS environment, so it cannot run concurrently with other tests.
  use ExUnit.Case, async: false

  @vars ["HTTP_PROXY", "http_proxy", "HTTPS_PROXY", "https_proxy"]

  setup context do
    envs = Map.get(context, :envs, %{})
    previous = Map.new(@vars ++ Map.keys(envs), &{&1, System.get_env(&1)})

    Enum.each(@vars, &System.delete_env/1)
    Enum.each(envs, fn {name, value} -> System.put_env(name, value) end)

    on_exit(fn ->
      Enum.each(previous, fn
        {name, nil} -> System.delete_env(name)
        {name, value} -> System.put_env(name, value)
      end)
    end)
  end

  @tag envs: %{
         "HTTP_PROXY" => "http://proxy.local:3128",
         "https_proxy" => "http://secure.local:3128"
       }
  test "proxy_for_scheme/1 returns the configured proxy" do
    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == "http://proxy.local:3128"
    assert Esbuild.NpmRegistry.proxy_for_scheme("https") == "http://secure.local:3128"
  end

  @tag envs: %{"HTTP_PROXY" => "", "HTTPS_PROXY" => "  "}
  test "proxy_for_scheme/1 handles blank variables as if they were not set" do
    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == nil
    assert Esbuild.NpmRegistry.proxy_for_scheme("https") == nil
  end

  @tag envs: %{"HTTP_PROXY" => "", "http_proxy" => "http://proxy.local:3128"}
  test "proxy_for_scheme/1 falls back to the lowercase variable when the uppercase one is blank" do
    assert Esbuild.NpmRegistry.proxy_for_scheme("http") == "http://proxy.local:3128"
  end

  @tag envs: %{"HTTPS_PROXY" => "  http://secure.local:3128 "}
  test "proxy_for_scheme/1 trims surrounding whitespace" do
    assert Esbuild.NpmRegistry.proxy_for_scheme("https") == "http://secure.local:3128"
  end
end
