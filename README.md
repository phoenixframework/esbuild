# Esbuild

[![CI](https://github.com/phoenixframework/esbuild/actions/workflows/main.yml/badge.svg)](https://github.com/phoenixframework/esbuild/actions/workflows/main.yml)

Mix tasks for installing and invoking [esbuild](https://github.com/evanw/esbuild/).

## Installation

If you are going to build assets in production, then you add
`esbuild` as dependency on all environments but only start it
in dev:

```elixir
def deps do
  [
    {:esbuild, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

However, if your assets are precompiled during development,
then it only needs to be a dev dependency:

```elixir
def deps do
  [
    {:esbuild, "~> 0.1", only: :dev}
  ]
end
```

Once installed, change your `config/config.exs` to pick your
esbuild version of choice:

```elixir
config :esbuild, version: "0.12.15"
```

Now you can install esbuild by running:

```bash
$ mix esbuild.install
```

And invoke esbuild with:

```bash
$ mix esbuild default assets/js/app.js --bundle --minify --target=es2016 --outdir=priv/static/assets/
```

The executable is kept at `_build/esbuild`.

### Profiles

The first argument to `esbuild` is the execution profile.
You can define multiple execution profiles with the current
directory, the OS enviroment, and default arguments to the
`esbuild` task:

```elixir
config :esbuild,
  version: "0.12.15",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

When `mix esbuild default` is invoked, the task arguments will be appended
to the ones configured above.

## License

Copyright (c) 2021 Wojtek Mach, José Valim.

esbuild source code is licensed under the [MIT License](LICENSE.md).
