# rezen/tap

Homebrew formulae for tools published by [rezen](https://github.com/rezen). Every formula builds from a tagged source release.

```sh
brew install rezen/tap/<formula>
```

## Formulae

| Formula | Description |
| --- | --- |
| [`middles`](Formula/middles.rb) | [Policy-enforcing package registry proxy](https://github.com/rezen/middles) |
| [`smash`](Formula/smash.rb) | [Policy-controlled shell for install scripts](https://github.com/rezen/smash) |

### middles

The formula installs a default configuration at `$(brew --prefix)/etc/middles/middles.toml`, with the cache under `$(brew --prefix)/var/middles`. Homebrew keeps that file across upgrades; when the shipped default changes, the new copy lands beside it as `middles.toml.default`. The unmodified example configuration is at `$(brew --prefix)/share/middles/middles.example.toml`. Middles can also run with its built-in defaults, without a configuration file.

Run middles as a service with:

```sh
brew services start middles
```

The service reads `etc/middles/middles.toml` and logs to `$(brew --prefix)/var/log/middles.log`. After editing the configuration, validate it and restart:

```sh
middles --config "$(brew --prefix)/etc/middles/middles.toml" --check
brew services restart middles
```

#### When Homebrew itself goes through middles

If you point Homebrew at middles with `HOMEBREW_ARTIFACT_DOMAIN=http://127.0.0.1:6280/homebrew` and `HOMEBREW_ARTIFACT_DOMAIN_NO_FALLBACK=1`, every brew command depends on middles, including the ones that would fix it. Homebrew upgrades its Portable Ruby before running most commands, so even `brew services start middles` fails when it can't download.

- **middles is down** (`curl: (7) Failed to connect`): check `brew services info middles` and the log, or run it in the foreground with `middles --config "$(brew --prefix)/etc/middles/middles.toml"`.
- **middles is up but returns 403** (`digest is not a verified bottle/config on a configured platform`): the Homebrew adapter only serves official core bottles, and Homebrew's Portable Ruby isn't one. This happens each time Homebrew moves to a new Portable Ruby.

In either case, bypass the proxy for one command, then carry on as normal:

```sh
env -u HOMEBREW_ARTIFACT_DOMAIN -u HOMEBREW_ARTIFACT_DOMAIN_NO_FALLBACK brew vendor-install ruby
env -u HOMEBREW_ARTIFACT_DOMAIN -u HOMEBREW_ARTIFACT_DOMAIN_NO_FALLBACK brew services restart middles
```

## Updating a formula

After a matching `MAJOR.MINOR.PATCH` release tag is published in the upstream repository:

```sh
scripts/update-homebrew-formula.sh <formula> <version>
scripts/lint.sh
brew audit --strict --formula rezen/tap/<formula>
brew install --build-from-source rezen/tap/<formula>
brew test rezen/tap/<formula>
```

For example, `scripts/update-homebrew-formula.sh middles 0.2.2`.

The update script reads the upstream repository and tag prefix from the formula's current `url`, downloads the tagged source archive, verifies the version declared in its `Cargo.toml` when there is one, and records the new `url` and `sha256` in the formula, along with `version` when the formula declares one.

`scripts/lint.sh` runs `brew style` (RuboCop with Homebrew's formula cops) over `Formula/`, ShellCheck over `scripts/`, and actionlint over the workflows. It needs `brew install shellcheck actionlint`; `scripts/lint.sh --fix` applies RuboCop's autocorrections.

## Adding a formula

1. Create `Formula/<name>.rb` with a GitHub release-tag `url` and a `sha256`, so the update script can maintain it. Leave out `version`; the strict audit rejects it as redundant with a tag URL.
2. Run the checks above.
3. Add a row to the table in this README.

CI runs `scripts/lint.sh` and, for every file in `Formula/`, the audit, build and test checks on every push and pull request.
