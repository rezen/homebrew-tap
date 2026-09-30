# rezen/tap

Homebrew formulae for tools published by [rezen](https://github.com/rezen). Every formula builds from a tagged source release.

```sh
brew install rezen/tap/<formula>
```

## Formulae

| Formula | Description |
| --- | --- |
| [`middles`](Formula/middles.rb) | [Policy-enforcing package registry proxy](https://github.com/rezen/middles) |

### middles

The formula installs an example configuration at `$(brew --prefix)/share/middles/middles.example.toml`. Middles can also run with its built-in defaults, without a configuration file.

## Updating a formula

After a matching `MAJOR.MINOR.PATCH` release tag is published in the upstream repository:

```sh
scripts/update-homebrew-formula.sh <formula> <version>
brew style Formula/<formula>.rb
brew audit --strict --formula rezen/tap/<formula>
brew install --build-from-source rezen/tap/<formula>
brew test rezen/tap/<formula>
```

For example, `scripts/update-homebrew-formula.sh middles 0.2.2`.

The update script reads the upstream repository and tag prefix from the formula's current `url`, downloads the tagged source archive, verifies the version declared in its `Cargo.toml` when there is one, and records the new `url`, `version`, and `sha256` in the formula.

## Adding a formula

1. Create `Formula/<name>.rb` with a GitHub release-tag `url`, a `version`, and a `sha256`, so the update script can maintain it.
2. Run the checks above.
3. Add a row to the table in this README.

CI discovers every file in `Formula/` and runs the same checks for each one on every push and pull request.
