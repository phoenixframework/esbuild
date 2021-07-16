# Esbuild

Mix tasks for installing and invoking [esbuild](https://github.com/evanw/esbuild/).

## Installation

Add `esbuild` dependency but only start it in dev:

```elixir
def deps do
  [
    {:esbuild, "~> 0.1.0", runtime: Mix.env() == :dev}
  ]
end
```

Then use `config/config.exs` to configure your esbuild version
of choice:

```elixir
config :esbuild, :version, "0.12.15"
```

Now you can install esbuild by running:

    $ mix esbuild.install

And invoke esbuild with:

    $ mix esbuild assets/js/app.js --bundle --minify --target=es2016 --outfile=priv/static/assets/app.js

## License

Copyright (c) 2021, Wojtek Mach, José Valim.

esbuild source code is licensed under the [MIT License](LICENSE.md).
