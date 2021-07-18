defmodule EsbuildTest do
  use ExUnit.Case, async: true

  test "run on default" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:default, ["--version"]) == 0
           end) =~ "0.12.15"
  end

  test "run on profile" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(:another, []) == 0
           end) =~ "0.12.15"
  end
end
