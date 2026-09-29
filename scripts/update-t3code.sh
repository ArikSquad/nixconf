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
      | select((.name // "") | startswith("T3 Code Nightly "))
      | select(.tag_name | test("^v[0-9]+\\.[0-9]+\\.[0-9]+-nightly\\.[0-9]{8}\\.[0-9]+$"))
      | . as $release
      | .assets[]?
      | select(.name == ("T3-Code-" + ($release.tag_name | sub("^v"; "")) + "-x86_64.AppImage"))
      | {tag: $release.tag_name, name, url: .browser_download_url}
    ]
    | sort_by(
        .tag
        | capture("^v(?<major>[0-9]+)\\.(?<minor>[0-9]+)\\.(?<patch>[0-9]+)-nightly\\.(?<date>[0-9]{8})\\.(?<build>[0-9]+)$")
        | [(.major | tonumber), (.minor | tonumber), (.patch | tonumber), (.date | tonumber), (.build | tonumber)]
      )
    | last
    | if . == null then empty else [.name, .url] | @tsv end
  ')

read -r asset_name asset_url <<< "$release"
if [[ -z "${asset_name:-}" || -z "${asset_url:-}" ]]; then
  echo "No T3 Code nightly x86_64 AppImage release found" >&2
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
