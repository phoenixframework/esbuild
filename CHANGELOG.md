# CHANGELOG

## v0.4.0 (2021-11-27)

  * Attach system target architecture to saved esbuild executable
  * Store download on user cache directory
  * Update esbuild to 0.14.0
  * Add support for 32bit linux

## v0.3.4 (2021-10-30)

  * Support armv7l
  * Update esbuild to 0.13.10

## v0.3.3 (2021-10-11)

  * Fallback if Mix.Project is not available
  * Update esbuild to 0.13.4

## v0.3.2 (2021-10-06)

  * Do not load runtime config by default on `esbuild.install` task
  * Update latest known `esbuild` version
  * Allow `config :esbuild, :path, path` to configure the path to the esbuild install
  * Support `HTTP_PROXY/HTTPS_PROXY` to fetch esbuild

## v0.3.1 (2021-09-08)

  * Fix target detection on arm32

## v0.3.0 (2021-09-05)

  * No longer load `config/runtime.exs` by default, instead support `--runtime-config` flag
  * Update initial `esbuild` version to `0.12.18`

## v0.2.2 (2021-08-28)

  * `mix esbuild.install --if-missing` also checks version

## v0.2.1 (2021-08-09)

  * Require Elixir v1.10
  * Make sure `bin_path` directory exists before writing to it
  * Fix target detection for FreeBSD

## v0.2.0 (2021-07-29)

  * Bump to esbuild 0.12.17

## v0.1.3 (2021-07-21)

  * Fix Windows support

## v0.1.2 (2021-07-18)

  * Improve docs and error messages
  * Reenable esbuild task

## v0.1.1 (2021-07-18)

  * Fix target detection on ARM Macs and OTP < 24

## v0.1.0 (2021-07-18)

  * First release
