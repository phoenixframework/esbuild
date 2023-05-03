defmodule EsbuildTest do
  use ExUnit.Case, async: true

  @version Esbuild.latest_version()

  test "run on default" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:default, ["--version"]) == 0
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
             assert Esbuild.run(:default, ["--version"]) == 0
           end) =~ "0.12.15"

    Application.delete_env(:esbuild, :version)

    Mix.Task.rerun("esbuild.install", ["--if-missing"])

    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:default, ["--version"]) == 0
           end) =~ @version
  after
    Application.delete_env(:esbuild, :version)
  end

  test "install and run multiple concurrently" do
    bin_path = Esbuild.bin_path()

    assert :ok = File.exists?(bin_path) && File.rm!(bin_path)

    results =
      [:extra1, :extra2, :extra3]
      |> Enum.map(fn profile ->
        Application.put_env(:esbuild, profile, args: ["--version"])

        Task.async(fn ->
          ret_code = Esbuild.install_and_run(profile, [])
          # Let the first finished task set the binary file to read and execute only,
          # so that the others will fail if they try to overwrite it.
          File.chmod!(bin_path, 0o500)
          ret_code == 0
        end)
      end)
      |> Task.await_many(:infinity)

    File.chmod!(bin_path, 0o700)
    assert results |> Enum.all?()
  end
end
