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
config :esbuild, version: "0.12.17"
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

## Profiles

The first argument to `esbuild` is the execution profile.
You can define multiple execution profiles with the current
directory, the OS enviroment, and default arguments to the
`esbuild` task:

```elixir
config :esbuild,
  version: "0.12.17",
  default: [
    args: ~w(js/app.js),
    cd: Path.expand("../assets", __DIR__)
  ]
```

When `mix esbuild default` is invoked, the task arguments will be appended
to the ones configured above.

## Adding to Phoenix

To add `esbuild` to an application using Phoenix, you need only four steps.

First add it as a dependency in your `mix.exs`:

```elixir
def deps do
  [
    {:esbuild, "~> 0.1", runtime: Mix.env() == :dev}
  ]
end
```

Now let's configure `esbuild` to use `assets/js/app.js` as an entry point and
write to `priv/static/assets`:

```elixir
config :esbuild,
  version: "0.12.17",
  default: [
    args: ~w(js/app.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]
```

> Make sure the "assets" directory from priv/static is listed in the
> :only option for Plug.Static in your lib/my_app_web/endpoint.ex

For development, we want to enable watch mode. So find the `watchers`
configuration in your `config/dev.exs` and add:

```elixir
  esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
```

Note we are inlining source maps and enabling the file system watcher.

Finally, back in your `mix.exs`, make sure you have a `assets.deploy`
alias for deployments, which will also use the `--minify` option:

```elixir
"assets.deploy": ["esbuild default --minify", "phx.digest"]
```

## License

Copyright (c) 2021 Wojtek Mach, José Valim.

esbuild source code is licensed under the [MIT License](LICENSE.md).
