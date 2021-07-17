defmodule EsbuildTest do
  use ExUnit.Case, async: true

  test "run" do
    assert ExUnit.CaptureIO.capture_io(fn ->
             assert Esbuild.run(["--version"]) == 0
           end) =~ "0.12.15"
  end
end
