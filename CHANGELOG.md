# CHANGELOG

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
