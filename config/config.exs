import Config

config :esbuild,
  version: "0.14.0",
  another: [
    args: ["--version"]
  ]

config :esbuild, cacerts_path: System.get_env("ESBUILD_CACERTS_PATH")
