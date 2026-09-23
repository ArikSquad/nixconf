#!/usr/bin/env bash
set -euo pipefail

cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.."

release=$(curl --fail --silent --show-error \
  -H "Accept: application/vnd.github+json" \
  "https://api.github.com/repos/pingdotgg/t3code/releases?per_page=100" \
  | jq -r '
    [
      .[]
      | select(.draft == false)
      | .assets[]?
      | select(.name | endswith("-x86_64.AppImage"))
      | {name, url: .browser_download_url}
    ]
    | first
    | if . == null then empty else [.name, .url] | @tsv end
  ')

read -r asset_name asset_url <<< "$release"
if [[ -z "${asset_name:-}" || -z "${asset_url:-}" ]]; then
  echo "No T3 Code x86_64 AppImage release asset found" >&2
  exit 1
fi

version="${asset_name#T3-Code-}"
version="${version%-x86_64.AppImage}"
hash=$(nix store prefetch-file --json "$asset_url" | jq -r .hash)

VERSION="$version" HASH="$hash" python3 - <<'PY'
import os
from pathlib import Path

path = Path("pkgs/t3code.nix")
text = path.read_text()
lines = text.splitlines(keepends=True)


def replace_line(prefix, value):
    for index, line in enumerate(lines):
        if line.startswith(prefix):
            newline = "\n" if line.endswith("\n") else ""
            lines[index] = f'{prefix}{value}";{newline}'
            return
    raise SystemExit(f"Could not find line starting with {prefix!r}")


replace_line('  version = "', os.environ["VERSION"])
replace_line('    hash = "', os.environ["HASH"])
path.write_text("".join(lines))
PY

nix build .#t3code --no-link --print-build-logs
