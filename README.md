# Esbuild

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
config :esbuild, :version, "0.12.15"
```

Now you can install esbuild by running:

    $ mix esbuild.install

And invoke esbuild with:

    $ mix esbuild assets/js/app.js --bundle --minify --target=es2016 --outfile=priv/static/assets/app.js

The executable is kept at `_build/esbuild`.

## License

Copyright (c) 2021, Wojtek Mach, José Valim.

esbuild source code is licensed under the [MIT License](LICENSE.md).
