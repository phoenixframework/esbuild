defmodule EsbuildTest do
  use ExUnit.Case, async: true

  @version Esbuild.latest_version()

  test "run on default" do
    Application.put_env(:esbuild, :default, args: ["--version"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:default, []) == 0
           end) =~ @version
  end

  test "run on profile" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:another, []) == 0
           end) =~ @version
  end

  test "updates on install" do
    Application.put_env(:esbuild, :version, "0.12.15")

    Mix.Task.rerun("esbuild.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:another, []) == 0
           end) =~ "0.12.15"

    Application.delete_env(:esbuild, :version)

    Mix.Task.rerun("esbuild.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:another, []) == 0
           end) =~ @version
  end
end
