## v0.2.5

- Support `cargo_extra_args` option to pass additional flags to cargo

## v0.2.4

- Luarocks 3.12 compatibility

## v0.2.3

- Add option to include lua files
- Set `LUA_ROCKSPEC_PACKAGE`/`LUA_ROCKSPEC_VERSION` environment variables during build

## v0.2.2

- Pass correct `target-dir` arg to cargo instead of `target` (mlua-rs/luarocks-build-rust-mlua#12)

## v0.2.1 (yanked)

- Pass `target_path` to cargo if it's set (mlua-rs/luarocks-build-rust-mlua#9)
- Re-enable support for LuaRocks 3.1.x (mlua-rs/luarocks-build-rust-mlua#10)

## v0.2.0

This release lines up with the mlua v0.9 changes

- Do not require lua headers or lib on Windows (modules are linked with `lua5x.dll`)
- Never pass `vendored` feature (makes no sense in the module mode)
- Support `default_features = false` option to pass `--no-default-features` to cargo
- Support `features` option to pass additional features to cargo
