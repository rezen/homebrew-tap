#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s [--fix]\n' "${0##*/}"
  printf 'Lint the formulae with brew style (RuboCop), the shell scripts with ShellCheck,\n'
  printf 'and the GitHub Actions workflows with actionlint.\n'
}

fix=()
case ${1:-} in
  '') ;;
  --fix) fix=(--fix) ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    usage >&2
    exit 2
    ;;
esac

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$root"

missing=()
for tool in brew shellcheck actionlint; do
  command -v "$tool" >/dev/null || missing+=("$tool")
done
if ((${#missing[@]})); then
  printf 'Missing %s. Install Homebrew, then: brew install shellcheck actionlint\n' "${missing[*]}" >&2
  exit 1
fi

status=0

# brew style runs RuboCop with Homebrew's own configuration and formula cops.
# It is pointed at Formula only: on shell scripts it applies Homebrew's internal
# shfmt style, which does not suit the scripts here.
printf '==> brew style\n'
brew style "${fix[@]}" Formula || status=1

printf '==> shellcheck\n'
shellcheck scripts/*.sh || status=1

printf '==> actionlint\n'
actionlint || status=1

exit "$status"
