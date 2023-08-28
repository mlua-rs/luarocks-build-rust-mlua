## v0.2.0

This release lines up with the mlua v0.9 changes

- Do not require lua headers or lib on Windows (modules are linked with `lua5x.dll`)
- Never pass `vendored` feature (makes no sense in the module mode)
- Support `default_features = false` option to pass `--no-default-features` to cargo
- Support `features` option to pass additional features to cargo
