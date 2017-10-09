# Changelog

## v0.3.0

### Bug fixes

- Fix compilation error with Commanded v0.14.0 due to removal of `Commanded.EventStore.TypeProvider` macro, replaced with runtime config lookup ([#5](https://github.com/slashdotdash/commanded-extreme-adapter/issues/5)).

## v0.2.0

### Enhancements

- Raise an exception if `:stream_prefix` configuration contains a dash character ("-") as this does not work with subscriptions ([#3](https://github.com/slashdotdash/commanded-extreme-adapter/issues/3)).

## v0.1.0

- Initial release.
