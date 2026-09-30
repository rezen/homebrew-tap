#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'Usage: %s FORMULA MAJOR.MINOR.PATCH\n' "${0##*/}"
  printf 'Update Formula/FORMULA.rb from a published release tag of its upstream GitHub repository.\n'
}

if [[ ${1:-} == --help || ${1:-} == -h ]]; then
  usage
  exit 0
fi
if (( $# != 2 )); then
  usage >&2
  exit 2
fi

formula=${1%.rb}
formula=${formula##*/}
version=${2#v}
if [[ ! $version =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
  printf 'Version must be MAJOR.MINOR.PATCH: %s\n' "$2" >&2
  exit 2
fi

root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
formula_file="$root/Formula/$formula.rb"
if [[ ! -f $formula_file ]]; then
  printf 'No such formula: Formula/%s.rb\n' "$formula" >&2
  exit 1
fi

# The formula's current url names the upstream repository and the tag prefix.
current_url=$(perl -ne 'print $1 if /^  url "([^"]+)"$/' "$formula_file")
if [[ ! $current_url =~ ^(https://github\.com/[^/]+/[^/]+)/archive/refs/tags/(v?)[^/]+\.tar\.gz$ ]]; then
  printf 'Formula url is not a GitHub release-tag archive: %s\n' "${current_url:-<missing>}" >&2
  exit 1
fi
repo=${BASH_REMATCH[1]}
tag="${BASH_REMATCH[2]}$version"
url="$repo/archive/refs/tags/$tag.tar.gz"

archive=$(mktemp)
trap 'rm -f "$archive"' EXIT

curl --fail --location --silent --show-error --retry 3 --output "$archive" "$url"
members=$(tar -tzf "$archive")
archive_root=$(printf '%s\n' "$members" | sed -n '1{s@/.*@@;p;}')

# Verify the version the archive declares, for the manifests we know how to read.
if printf '%s\n' "$members" | grep -qx "$archive_root/Cargo.toml"; then
  archive_version=$(tar -xOzf "$archive" "$archive_root/Cargo.toml" | perl -ne '
    if (/^\s*\[([^\]]+)\]\s*$/) { $section = $1; next }
    if (/^\s*version\s*=\s*"([^"]+)"/) {
      $package = $1 if $section eq "package";
      $workspace = $1 if $section eq "workspace.package";
    }
    END { print $package // $workspace // "" }
  ')
  if [[ -z $archive_version ]]; then
    printf 'Could not find a package version in %s/Cargo.toml.\n' "$archive_root" >&2
    exit 1
  fi
  if [[ $archive_version != "$version" ]]; then
    printf 'Downloaded archive declares Cargo version %s; expected %s.\n' "$archive_version" "$version" >&2
    exit 1
  fi
else
  printf 'No Cargo.toml in %s; skipping manifest version check.\n' "$archive_root" >&2
fi

sha256=$(shasum -a 256 "$archive" | awk '{print $1}')

FORMULA=$formula FORMULA_URL=$url FORMULA_VERSION=$version FORMULA_SHA256=$sha256 perl -0pi -e '
  BEGIN {
    $url = $ENV{FORMULA_URL};
    $version = $ENV{FORMULA_VERSION};
    $sha = $ENV{FORMULA_SHA256};
  }
  s{^  url "[^"]+"\n  version "[^"]+"\n  sha256 "[0-9a-f]{64}"$}
   {  url "$url"\n  version "$version"\n  sha256 "$sha"}m
    or die "Could not update Formula/$ENV{FORMULA}.rb\n";
' "$formula_file"

printf 'Updated Formula/%s.rb for %s (%s).\n' "$formula" "$tag" "$sha256"
